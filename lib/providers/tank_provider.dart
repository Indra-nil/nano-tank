import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/tank.dart';
import '../services/ble_service.dart';
import '../services/storage_service.dart';

class TankProvider extends ChangeNotifier {
  List<Tank> _tanks = [];
  final BleService _bleService = BleService();

  TankProvider() {
    _init();
  }

  Future<void> _init() async {
    _tanks = StorageService.getTanks();
    _startBackgroundScan();
    notifyListeners();
  }

  List<Tank> get tanks => _tanks;

  /// ✅ SCAN FOR NEW TANKS (AUTO CONNECT)
  Future<void> scanAndAddTank(BuildContext context) async {
    await BleService.requestPermissions();

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    final subscription = FlutterBluePlus.scanResults.listen((results) async {
      for (final r in results) {
        if (r.device.platformName.contains('TankController')) {
          FlutterBluePlus.stopScan();

          await scanAndAddTankWithId(
            context,
            r.device.remoteId.str,
          );

          break;
        }
      }
    });

    await Future.delayed(const Duration(seconds: 10));
    await FlutterBluePlus.stopScan();
    await subscription.cancel();
  }

  /// ✅ ADD + CONNECT TANK (FIXED & ASYNC)
  Future<void> scanAndAddTankWithId(
    BuildContext context,
    String deviceId,
  ) async {
    // 🔒 DUPLICATE CHECK
    final exists = _tanks.any((t) => t.bleDeviceId == deviceId);
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Tank already added'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // ⏳ CONNECT BLE FIRST
    await _bleService.connect(deviceId);

    // ✅ CREATE TANK
    final newTank = Tank(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Tank ${_tanks.length + 1}',
      bleDeviceId: deviceId,
      connected: true,
      lowPumps: 0,
    );

    _tanks.add(newTank);
    StorageService.saveTank(newTank);
    notifyListeners();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Connected to ${newTank.name}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// ✅ RENAME TANK
  void renameTank(Tank tank, String newName, BuildContext context) {
    tank.name = newName;
    StorageService.saveTanks(_tanks);
    notifyListeners();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Renamed to "$newName"'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// ✅ REFRESH CONNECTION
  Future<void> refreshTank(Tank tank) async {
    try {
      await _bleService.connect(tank.bleDeviceId);
      tank.connected = true;
    } catch (_) {
      tank.connected = false;
    }
    notifyListeners();
  }

  /// ✅ BACKGROUND SCAN
  void _startBackgroundScan() {
    Timer.periodic(const Duration(minutes: 30), (_) {
      _scanForKnownTanks();
    });
  }

  void _scanForKnownTanks() async {
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    await FlutterBluePlus.stopScan();
  }

  /// ✅ REMOVE TANK
  void removeTank(Tank tank) {
    _tanks.remove(tank);
    StorageService.saveTanks(_tanks);
    notifyListeners();
  }

  /// ✅ DEBUG TANK
  void addTestTank() {
    final newTank = Tank(
      id: 'test_${_tanks.length}',
      name: 'Test Tank ${_tanks.length + 1}',
      bleDeviceId: 'TEST_${_tanks.length}',
      connected: true,
      lowPumps: 0,
    );
    _tanks.add(newTank);
    StorageService.saveTank(newTank);
    notifyListeners();
  }
}