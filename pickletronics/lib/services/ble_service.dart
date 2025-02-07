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

      var services = await device.discoverServices();

      for (var service in services) {
        for (var c in service.characteristics) {
          if (c.uuid.toString().toUpperCase().contains(CHARACTERISTIC_UUID)) {
            _characteristic = c;
            await _readUntilComplete();
            break;
          }
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _readUntilComplete() async {
    bool isDumpComplete = false;

    while (!isDumpComplete && _characteristic != null) {
      try {
        final value = await _characteristic!.read();
        if (value.isEmpty) continue;

        _processData(value);

        final chunk = utf8.decode(value);
        if (chunk.trim() == 'Dumped all sessions.') {
          isDumpComplete = true;
          break;
        }

        await Future.delayed(const Duration(milliseconds: 50));
      } catch (e) {
        break;
      }
    }
  }

  void _processData(List<int> data) {
    final chunk = utf8.decode(data);
    _incomingBuffer += chunk;

    while (_incomingBuffer.contains('\n')) {
      final newlineIndex = _incomingBuffer.indexOf('\n');
      var line = _incomingBuffer.substring(0, newlineIndex).trim();
      _incomingBuffer = _incomingBuffer.substring(newlineIndex + 1);

      if (line.isEmpty) {
        continue;
      }

      if (RegExp(r'^\d+$').hasMatch(line) ||
          line.contains(',') ||
          line == "End of file reached." ||
          line == "Dumped all sessions.") {
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