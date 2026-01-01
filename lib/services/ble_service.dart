import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';

class BleService {
  static const String SERVICE_UUID = "12345678-1234-1234-1234-123456789abc";
  static const String STATUS_UUID = "87654321-4321-4321-4321-cba987654321";
  static const String CONFIG_UUID = "11111111-1111-1111-1111-111111111111";
  static const String RENAME_UUID = "33333333-3333-3333-3333-333333333333";

  BluetoothDevice? device;
  BluetoothCharacteristic? statusChar;
  BluetoothCharacteristic? configChar;
  BluetoothCharacteristic? renameChar;

  /// Request required BLE permissions
  static Future<void> requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.locationWhenInUse,
    ].request();
  }

  /// Connect to BLE device and discover characteristics
  Future<void> connect(String deviceId) async {
    await requestPermissions();

    device = BluetoothDevice.fromId(deviceId);

    await device!.connect(
      timeout: const Duration(seconds: 10),
      autoConnect: false,
    );

    final services = await device!.discoverServices();

    final service = services.firstWhere(
      (s) => s.uuid == Guid(SERVICE_UUID),
      orElse: () => throw Exception("Service not found"),
    );

    statusChar = service.characteristics.firstWhere(
      (c) => c.uuid == Guid(STATUS_UUID),
      orElse: () => throw Exception("Status characteristic not found"),
    );

    configChar = service.characteristics.firstWhere(
      (c) => c.uuid == Guid(CONFIG_UUID),
      orElse: () => throw Exception("Config characteristic not found"),
    );

    renameChar = service.characteristics.firstWhere(
      (c) => c.uuid == Guid(RENAME_UUID),
      orElse: () => throw Exception("Rename characteristic not found"),
    );

    await statusChar!.setNotifyValue(true);

    statusChar!.lastValueStream.listen((value) {
      print('Status update: $value');
    });
  }

  /// Rename tank
  Future<void> renameTank(String newName) async {
    if (renameChar == null) return;
    final value = utf8.encode(newName);
    await renameChar!.write(value, withoutResponse: false);
  }

  /// Write configuration JSON
  Future<void> writeConfig(Map<String, dynamic> config) async {
    if (configChar == null) return;
    final jsonString = jsonEncode(config);
    final value = utf8.encode(jsonString);
    await configChar!.write(value, withoutResponse: false);
  }

  /// Disconnect BLE device
  Future<void> disconnect() async {
    await device?.disconnect();
    device = null;
  }
}