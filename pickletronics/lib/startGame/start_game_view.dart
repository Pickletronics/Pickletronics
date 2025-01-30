import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';

final Logger _logger = Logger();

Future<void> _requestPermissions() async {
  await Permission.bluetoothScan.request();
  await Permission.bluetoothConnect.request();
  await Permission.location.request();
}

class StartGameView extends StatefulWidget {
  const StartGameView({super.key});

  @override
  StartGameViewState createState() => StartGameViewState();
}

class StartGameViewState extends State<StartGameView> {
  //final FlutterBluePlus _flutterBlue = FlutterBluePlus();
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
        if (!_devicesList.contains(r.device)) {
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
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: isScanning ? null : _startScanning,
          child: Text(isScanning ? 'Scanning...' : 'Scan for Nearby Devices'),
        ),
        const SizedBox(height: 20),
        if (_devicesList.isNotEmpty)
          Expanded(
            child: ListView.builder(
              itemCount: _devicesList.length,
              itemBuilder: (context, index) {
                final device = _devicesList[index];
                return ListTile(
                  title: Text(
                    device.platformName.isNotEmpty ? device.platformName : 'Unknown Device',
                    style: const TextStyle(fontSize: 18),
                  ),
                  subtitle: Text('ID: ${device.remoteId}'),
                  trailing: const Icon(Icons.bluetooth),
                  onTap: () {
                    _showDeviceModal(device);
                  },
                );
              },
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              'No devices found. Tap "Pair Device" to scan.',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
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
    _logger.i('Connecting to device: ${device.platformName} (${device.remoteId})');
    await device.connect();
    _logger.i('Successfully connected to ${device.platformName}');

    // Discover services and characteristics
    List<BluetoothService> services = await device.discoverServices();
    if (services.isEmpty) {
      _showCharacteristicsDialog(device, []);
      return;
    }

    List<String> characteristics = [];
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        characteristics.add(
            'Characteristic: ${characteristic.uuid}, Properties: ${characteristic.properties}');
      }
    }

    _showCharacteristicsDialog(device, characteristics);
  } catch (e) {
    _logger.e('Failed to connect: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect to ${device.platformName}')),
      );
    }
  }
}

void _showCharacteristicsDialog(BluetoothDevice device, List<String> characteristics) {
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
