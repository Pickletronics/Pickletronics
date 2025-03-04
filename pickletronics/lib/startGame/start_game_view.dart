import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import 'package:pickletronics/viewSessions/SessionsTab.dart';
import 'package:pickletronics/viewSessions/session_parser.dart';

final Logger _logger = Logger();
String new_final_string = '';
bool isLoading = false;

Future<void> _requestPermissions() async {
  await Permission.bluetoothScan.request();
  await Permission.bluetoothConnect.request();
  await Permission.location.request();
  await Permission.storage.request(); // Request storage permission
}

class StartGameView extends StatefulWidget {
  const StartGameView({super.key});

  @override
  StartGameViewState createState() => StartGameViewState();
}

class StartGameViewState extends State<StartGameView> {
  final List<BluetoothDevice> _devicesList = [];
  late StreamSubscription<List<ScanResult>> _scanSubscription;
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    // Initialize scan results subscription
    _scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
      if (results.isNotEmpty) {
        ScanResult r = results.last; // Get the most recently found device
        if (!_devicesList.contains(r.device) && (r.device.platformName.isNotEmpty)) {
          setState(() {
            _devicesList.add(r.device); // Add device if not already in the list
          });
        }
        _logger.i('Device Found:');
        _logger.i('  Name: ${r.advertisementData.advName.isNotEmpty ? r.advertisementData.advName : "Unknown"}');
        _logger.i('  ID: ${r.device.remoteId}');
        _logger.i('  RSSI: ${r.rssi}');
        _logger.i('  Advertisement Data: ${r.advertisementData.toString()}');
      }
    }, onError: (e) => _logger.i('Error while scanning: $e'));
  }

  @override
  void dispose() {
    _scanSubscription.cancel(); // Clean up the subscription when disposing
    super.dispose();
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.grey[200],
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Center(
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              color: Colors.white,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.3,
                padding: const EdgeInsets.all(20),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Welcome Back!",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),
                    // Placeholder for analytics
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text("🏆 Best Session: 15 pts", style: TextStyle(fontSize: 18)),
                          Text("📊 Total Games: 32", style: TextStyle(fontSize: 18)),
                          Text("⏳ Avg. Game Duration: 10m", style: TextStyle(fontSize: 18)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Ensures button and device list stay beneath the dashboard
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 10), // Adds spacing

              // Pair Device Button
              ElevatedButton(
                onPressed: isScanning ? null : _startScanning,
                child: Text(isScanning ? 'Scanning...' : 'Scan for Nearby Devices'),
              ),

              const SizedBox(height: 20), // Adds spacing between button and list

              // List of Nearby Devices
              Expanded(
                child: _devicesList.isNotEmpty
                    ? ListView.builder(
                        itemCount: _devicesList.length,
                        itemBuilder: (context, index) {
                          final device = _devicesList[index];
                          return ListTile(
                            title: Text(
                              device.platformName.isNotEmpty
                                  ? device.platformName
                                  : 'Unknown Device',
                              style: const TextStyle(fontSize: 18),
                            ),
                            subtitle: Text('ID: ${device.remoteId}'),
                            trailing: const Icon(Icons.bluetooth),
                            onTap: () {
                              _showDeviceModal(device);
                            },
                          );
                        },
                      )
                    : const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: Text(
                          'No devices found. Tap "Pair Device" to scan.',
                          style: TextStyle(fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Future<void> _startScanning() async {
    await _requestPermissions();
    setState(() {
      isScanning = true;
      _devicesList.clear(); // Clear previous results
    });

    await FlutterBluePlus.adapterState.where((val) => val == BluetoothAdapterState.on).first;

    // Scan for ble devices with specific name/services
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    // Wait for scanning to stop
    await FlutterBluePlus.isScanning.where((val) => val == false).first;

    setState(() {
      isScanning = false;
    });

    _logger.i("Scanning complete.");
  }

void _showDeviceModal(BluetoothDevice device) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              device.platformName.isNotEmpty ? device.platformName : 'Unknown Device',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Close the modal
                await _connectAndReadCharacteristics(device);
              },
              child: const Text('Connect'),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _connectAndReadCharacteristics(BluetoothDevice device) async {
  try {
    setState(() => isLoading = true);
    _showLoadingDialog('Connecting to ${device.platformName}...');

    _logger.i('Connecting to device: ${device.platformName} (${device.remoteId})');

    await device.connect().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw TimeoutException('Connection timed out. Please try again.');
      },
    );
    
    _logger.i('Successfully connected to ${device.platformName}');

    // Update the loading dialog message
    Navigator.pop(context); // Close previous dialog
    _showLoadingDialog('Reading data from ${device.platformName}...');

    List<BluetoothService> services = await device.discoverServices();
    if (services.isEmpty) {
      Navigator.pop(context); // Close the loading dialog
      _showFailureModal("Failed to retrieve data from ${device.platformName}");
      return;
    }

    List<String> receivedData = [];
    bool sessionCreated = false;

    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.uuid.toString().contains('fef4')) {
          while (true) {
            try {
              List<int> value = await characteristic.read();
              String stringValue = utf8.decode(value);
              receivedData.add(stringValue);

              await _appendToLogFile(stringValue);
              print('Received: $stringValue');

              if (stringValue.contains('Dumped all sessions.')) {
                await Future.delayed(Duration(milliseconds: 100));
                List<Session> parsedSessions = await SessionParser().parseFile();
                print("Parsed sessions: ${parsedSessions.map((s) => s.toJson()).toList()}");

                sessionCreated = true;
                break;
              }
            } catch (e) {
              print('Error reading characteristic: $e');
              Navigator.pop(context); // Close the loading dialog
              _showFailureModal("Error reading data from ${device.platformName}");
              return;
            }
            await Future.delayed(Duration(milliseconds: 500));
          }
        }
      }
    }

    Navigator.pop(context); // Close the loading dialog

    if (sessionCreated) {
      _showSuccessModal("Session data successfully received from ${device.platformName}.");
    } else {
      _showFailureModal("No valid session data found from ${device.platformName}.");
    }

  } catch (e) {
    Navigator.pop(context); // Close the loading dialog
    _logger.e('Failed to connect: $e');
    _showFailureModal("Failed to connect to ${device.platformName}");
  } finally {
    setState(() => isLoading = false);
  }
}

void _showFailureModal(String message) {
  showDialog(
    context: context,
    barrierDismissible: false, // Requires user to tap "OK"
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}

void _showSuccessModal(String message) {
  showDialog(
    context: context,
    barrierDismissible: false, // Requires user to tap "OK"
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}

Future<void> _appendToLogFile(String data) async {
  try {
    final file = File('/storage/emulated/0/Download/bluetooth_log.txt');

    if (await file.exists()) {
      String existingContent = await file.readAsString();
      if (existingContent.contains('Dumped all sessions.')) {
        print('Previous session detected. Clearing log file.');
        await file.writeAsString(''); // Clear the file
      }
    }

    // Append data and ensure it is written before moving on
    await file.writeAsString('$data\n', mode: FileMode.append);
    print('Appended to file: $data');
    
    // Delay to allow filesystem sync before parsing
    await Future.delayed(Duration(milliseconds: 100));

  } catch (e) {
    print('Error writing to file: $e');
  }
}

void _showLoadingDialog(String message) {
  showDialog(
    context: context,
    barrierDismissible: false, // Prevents user from dismissing it manually
    builder: (BuildContext context) {
      return AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      );
    },
  );
}

void _showCharacteristicsDialog(BluetoothDevice device, List<String> characteristics, String temp) {

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(device.platformName.isNotEmpty ? device.platformName : 'Unknown Device'),
        content: characteristics.isNotEmpty
        ? SingleChildScrollView( // Ensures the content can scroll if it's long
            child: Text(
              characteristics.join("\n"), // Joins characteristics into a single string
              textAlign: TextAlign.left,  // Align text properly
            ),
          )
        : const Text('No data found'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}
}
