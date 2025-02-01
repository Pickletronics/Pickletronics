// lib/services/ble_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../providers/session_notifier.dart';

class BleService {
  static const String SERVICE_UUID = "0180";
  static const String CHARACTERISTIC_UUID = "FEF4";

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _characteristic;

  String _incomingBuffer = '';

  Function(String)? onTextReceived;

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      _connectedDevice = device;

      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        if (service.uuid.toString().toUpperCase().contains(SERVICE_UUID)) {
          for (var c in service.characteristics) {
            if (c.uuid.toString().toUpperCase().contains(CHARACTERISTIC_UUID)) {
              _characteristic = c;
              break;
            }
          }
        }
      }

      if (_characteristic == null) {
        print('Characteristic $CHARACTERISTIC_UUID not found!');
        await device.disconnect();
        throw Exception('Characteristic not found');
      }

      await _characteristic!.setNotifyValue(true);
      _characteristic!.value.listen((value) => _processData(value));
    } catch (e) {
      print('Error connecting to device: $e');
      rethrow;
    }
  }

  Future<void> requestDataFromDevice() async {
    if (_characteristic == null) {
      print('Cannot request data: characteristic is null!');
      return;
    }
    const command = 'SEND_ALL_SESSIONS\n';
    await _characteristic!.write(command.codeUnits, withoutResponse: false);
    print('Requested data from device...');
  }

  void _processData(List<int> data) {
    final chunk = utf8.decode(data);
    _incomingBuffer += chunk;

    while (_incomingBuffer.contains('\n')) {
      final newlineIndex = _incomingBuffer.indexOf('\n');
      final line = _incomingBuffer.substring(0, newlineIndex).trim();
      _incomingBuffer = _incomingBuffer.substring(newlineIndex + 1);

      if (line.isNotEmpty) {
        print('Got line: "$line"');
        onTextReceived?.call(line);
      }
    }
  }

  Future<void> disconnect(SessionNotifier sessionNotifier) async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
    }
    _connectedDevice = null;
    _characteristic = null;
    _incomingBuffer = '';

    sessionNotifier.resetAll();
  }

  bool get isConnected => _connectedDevice != null;
}
