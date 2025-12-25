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

  /// ✅ FIXED: Request BLE permissions
  static Future<void> requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.locationWhenInUse,
    ].request();
  }

  Future<void> connect(String deviceId) async {
    await requestPermissions();
    
    device = BluetoothDevice.fromId(deviceId);
    await device!.connect(timeout: Duration(seconds: 10));
    
    List<BluetoothService> services = await device!.discoverServices();
    BluetoothService service = services.firstWhere(
      (s) => s.uuid == Guid(BleService.SERVICE_UUID),  // ✅ FIXED
    );

    statusChar = service.characteristics.firstWhere((c) => c.uuid == Guid(BleService.STATUS_UUID));  // ✅ FIXED
    configChar = service.characteristics.firstWhere((c) => c.uuid == Guid(BleService.CONFIG_UUID));  // ✅ FIXED
    renameChar = service.characteristics.firstWhere((c) => c.uuid == Guid(BleService.RENAME_UUID));  // ✅ FIXED

    await statusChar!.setNotifyValue(true);
    statusChar!.lastValueStream.listen((value) {
      print('Status update: $value');
    });
  }

  Future<void> renameTank(String newName) async {
    List<int> value = utf8.encode(newName);
    await renameChar!.write(value);
  }

  Future<void> writeConfig(Map<String, dynamic> config) async {  // ✅ FIXED: Use Map instead
    String jsonString = jsonEncode(config);
    List<int> value = utf8.encode(jsonString);
    await configChar!.write(value);
  }

  Future<void> disconnect() async {
    await device?.disconnect();
  }
}
