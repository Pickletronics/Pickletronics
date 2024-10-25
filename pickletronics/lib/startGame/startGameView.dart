import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class StartGameView extends StatefulWidget {
  const StartGameView({Key? key}) : super(key: key);

  @override
  _StartGameViewState createState() => _StartGameViewState();
}

class _StartGameViewState extends State<StartGameView> {
  final FlutterBluePlus _flutterBlue = FlutterBluePlus();
  List<BluetoothDevice> _devicesList = [];
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
        print('${r.device.remoteId}: "${r.advertisementData.advName}" found');
      }
    }, onError: (e) => print(e));
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
                    device.name.isNotEmpty ? device.name : 'Unknown Device',
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
    setState(() {
      isScanning = true;
      _devicesList.clear(); // Clear previous results
    });

    // TODO: program currently stuck here when emulating, must test on a physical device
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

    print('Scanning complete.');
  }
}
