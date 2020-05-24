import 'dart:async';

import 'package:flutter/services.dart';

class BluetoothDevice {
  final String name;
  final String address;
  final String rssi;
  final String device_type;
  final bool paired;
  final bool nearby;

  const BluetoothDevice(this.name, this.address, this.rssi, this.device_type,
      {this.nearby = false, this.paired = false});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BluetoothDevice &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          address == other.address;

  @override
  int get hashCode => name.hashCode ^ address.hashCode;

  Map<String, dynamic> toMap() {
    return {'name': name, 'address': address, 'rssi': rssi, 'device_type': device_type};
  }

  @override
  String toString() {
    return 'BluetoothDevice{name: $name, address: $address, paired: $paired, nearby: $nearby, rssi: $rssi, device_type: $device_type}';
  }
}

class FlutterScanBluetooth {
  static final _singleton = FlutterScanBluetooth._();
  final MethodChannel _channel = const MethodChannel('flutter_scan_bluetooth');
  final List<BluetoothDevice> _pairedDevices = [];
  final StreamController<BluetoothDevice> _controller =
      StreamController.broadcast();
  final StreamController<bool> _scanStopped = StreamController.broadcast();

  factory FlutterScanBluetooth() => _singleton;

  FlutterScanBluetooth._() {
    _channel.setMethodCallHandler((methodCall) {
      switch (methodCall.method) {
        case 'action_new_device':
          _newDevice(methodCall.arguments);
          break;
        case 'action_scan_stopped':
          _scanStopped.add(true);
          break;
      }
    });
  }

  Stream<BluetoothDevice> get devices => _controller.stream;

  Stream<bool> get scanStopped => _scanStopped.stream;

  Future<void> startScan({pairedDevices = false}) async {
    final bondedDevices =
        await _channel.invokeMethod('action_start_scan', pairedDevices);
    for (var device in bondedDevices) {
      final d = BluetoothDevice(device['name'], device['address'],
          device['rssi'], device['device_type'],
          paired: true);
      _pairedDevices.add(d);
      _controller.add(d);
    }
  }

  Future<void> close() async {
    await _scanStopped.close();
    await _controller.close();
  }

  Future<void> stopScan() => _channel.invokeMethod('action_stop_scan');

  void _newDevice(device) {
    _controller.add(BluetoothDevice(
      device['name'],
      device['address'],
      device['rssi'],
      device['device_type'],
      nearby: true,
      paired: _pairedDevices.firstWhere(
              (item) => item.address == device['address'],
              orElse: () => null) !=
          null,
    ));
  }
}
