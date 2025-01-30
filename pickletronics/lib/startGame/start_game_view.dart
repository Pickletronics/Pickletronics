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
        _logger.i('${r.device.remoteId}: "${r.advertisementData.advName}" found');
      }
    }, onError: (e) => _logger.i(e));
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
          Center(
            child: ElevatedButton(
              onPressed: isScanning ? null : _startScanning,
              child: const Text('Pair Device'),
            ),
          ),
          const SizedBox(height: 20),
          if (_devicesList.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: _devicesList.map((device) {
                  return Text(
                    device.platformName.isNotEmpty ? device.platformName : 'Unknown Device',
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  );
                }).toList(),
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
    await FlutterBluePlus.startScan(
      withServices: [Guid("")], // Match any of the specified services
      withNames: [""], // Match any of the specified names
      timeout: const Duration(seconds: 15),
    );

    // Wait for scanning to stop
    await FlutterBluePlus.isScanning.where((val) => val == false).first;

    setState(() {
      isScanning = false;
    });

    _logger.i("Scanning complete.");
  }
}
