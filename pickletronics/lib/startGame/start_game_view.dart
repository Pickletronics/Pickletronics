// lib/StartGame/start_game_view.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';  // <--- Import Riverpod

import '../providers/session_provider.dart';         // <--- For sessionProvider
import '../services/ble_service.dart';              // <--- For BleService

final Logger _logger = Logger();

Future<void> _requestPermissions() async {
  await Permission.bluetoothScan.request();
  await Permission.bluetoothConnect.request();
  await Permission.location.request();
}

class StartGameView extends ConsumerStatefulWidget {
  const StartGameView({super.key});

  @override
  StartGameViewState createState() => StartGameViewState();
}

class StartGameViewState extends ConsumerState<StartGameView> {
  final List<BluetoothDevice> _devicesList = [];
  late StreamSubscription<List<ScanResult>> _scanSubscription;
  bool isScanning = false;

  // We create or retrieve a single BleService.
  // (You can make this a Riverpod provider if you like.)
  final BleService _bleService = BleService();

  @override
  void initState() {
    super.initState();
    // Initialize scan results subscription
    _scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
      if (results.isNotEmpty) {
        ScanResult r = results.last; // Get the most recently found device
        if (!_devicesList.contains(r.device) &&
            (r.device.platformName.isNotEmpty)) {
          setState(() {
            _devicesList.add(r.device);
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
    _scanSubscription.cancel();
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
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'No devices found. Tap "Scan for Nearby Devices" to scan.',
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
      _devicesList.clear();
    });

    await FlutterBluePlus.adapterState
        .where((val) => val == BluetoothAdapterState.on)
        .first;

    // Scan for ble devices
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
                device.platformName.isNotEmpty
                    ? device.platformName
                    : 'Unknown Device',
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
      // Attempt the connection with a timeout
      await device.connect().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Connection timed out. Please try again.');
        },
      );
      _logger.i('Successfully connected to ${device.platformName}');

      // ============== INTEGRATION WITH OUR BLE SERVICE + SESSIONS ==============
      // 1) We'll assign the onTextReceived callback so that each line
      //    we get from the device is forwarded to our SessionNotifier
      final sessionNotifier = ref.read(sessionProvider.notifier);

      _bleService.onTextReceived = (String line) {
        sessionNotifier.processIncomingLine(line);
      };

      // 2) Actually do discoverServices + set up notifications
      //    (Our BleService will do that automatically in connectToDevice)
      await _bleService.connectToDevice(device);

      // Optionally, we can request the device to send data if needed:
      // await _bleService.requestDataFromDevice();

      // If your device *automatically* sends data after connecting,
      // you might not need the requestDataFromDevice() call.
      // ============== END INTEGRATION =========================================

      // Now, for demonstration, we discover services again (like your code)
      List<BluetoothService> services = await device.discoverServices();
      if (services.isEmpty) {
        _showCharacteristicsDialog(device, []);
        return;
      }

      List<String> characteristics = [];
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          characteristics.add(
            'Characteristic: ${characteristic.uuid}, '
                'Properties: ${characteristic.properties}',
          );
        }
      }

      _showCharacteristicsDialog(device, characteristics);
    } catch (e) {
      _logger.e('Failed to connect: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect to ${device.platformName}'),
          ),
        );
      }
    }
  }

  void _showCharacteristicsDialog(
      BluetoothDevice device, List<String> characteristics) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            device.platformName.isNotEmpty
                ? device.platformName
                : 'Unknown Device',
          ),
          content: characteristics.isNotEmpty
              ? SingleChildScrollView(
            child: Text(
              characteristics.join("\n"),
              textAlign: TextAlign.left,
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
