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
                    _connectToDevice(device);
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

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      _logger.i('Connecting to device: ${device.platformName} (${device.remoteId})');
      await device.connect();
      _logger.i('Successfully connected to ${device.platformName}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connected to ${device.platformName}')),
        );
      }
    } catch (e) {
      _logger.e('Failed to connect: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect to ${device.platformName}')),
        );
      }
    }
  }
}
