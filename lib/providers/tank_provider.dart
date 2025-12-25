import 'dart:async';
import 'dart:io'; // ✅ Added for Platform check
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/tank.dart';
import '../services/ble_service.dart';
import '../services/storage_service.dart';

class TankProvider extends ChangeNotifier {
  List<Tank> _tanks = [];
  BleService _bleService = BleService();

  TankProvider() {
    _init();
  }

  Future<void> _init() async {
    _tanks = StorageService.getTanks();
    _startBackgroundScan();
    notifyListeners();
  }

  List<Tank> get tanks => _tanks;

  /// ✅ SCAN FOR NEW TANKS (DUPLICATE-PROOF)
  Future<void> scanAndAddTank(BuildContext context) async {
    // Request permissions
    await BleService.requestPermissions();
    
    // Scan for 10 seconds
    FlutterBluePlus.startScan(timeout: Duration(minutes: 1));
    
    final subscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.device.platformName.contains('TankController')) {
          // ✅ USE DUPLICATE-PROOF METHOD
          scanAndAddTankWithId(context, r.device.remoteId.str);
          FlutterBluePlus.stopScan();
          break;
        }
      }
    });
    
    // Stop scan after timeout
    await Future.delayed(Duration(seconds: 10));
    FlutterBluePlus.stopScan();
    subscription.cancel();
  }

  /// ✅ ADD TANK FROM BLE SCAN SCREEN (DUPLICATE-PROOF!)
  void scanAndAddTankWithId(BuildContext context, String deviceId) {
    // ✅ CHECK FOR DUPLICATES FIRST
    final existingTank = _tanks.firstWhere(
      (tank) => tank.bleDeviceId == deviceId,
      orElse: () => Tank(id: '', name: '', bleDeviceId: ''), // dummy
    );
    
    if (existingTank.bleDeviceId.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${existingTank.name} already exists!'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      print('⚠️ Duplicate tank skipped: $deviceId (${existingTank.name})');
      return; // 🚫 EXIT - NO DUPLICATE!
    }
    
    // ✅ NEW TANK ONLY
    final newTank = Tank(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Tank ${_tanks.length + 1}',
      bleDeviceId: deviceId,
      connected: false,
      lowPumps: 0,
    );
    _tanks.add(newTank);
    StorageService.saveTank(newTank);
    notifyListeners();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Added ${newTank.name}!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
    print('✅ Added NEW BLE tank: ${newTank.name} ($deviceId)');
  }

  /// ✅ RENAME TANK (NEW!)
  void renameTank(Tank tank, String newName, BuildContext context) {
    tank.name = newName;
    StorageService.saveTanks(_tanks);
    notifyListeners();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Renamed "${newName}"!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
    print('✅ Renamed ${tank.id}: $newName');
  }

  /// ✅ REFRESH TANK DATA
  Future<void> refreshTank(Tank tank) async {
    try {
      await _bleService.connect(tank.bleDeviceId);
      tank.connected = true;
      // Update live data from BLE
      notifyListeners();
    } catch (e) {
      tank.connected = false;
      notifyListeners();
    }
  }

  /// ✅ BACKGROUND SCAN
  void _startBackgroundScan() {
    Timer.periodic(Duration(minutes: 30), (timer) {
      _scanForKnownTanks();
    });
  }

  void _scanForKnownTanks() async {
    FlutterBluePlus.startScan(timeout: Duration(seconds: 5));
    // Check connection status for known tanks
    FlutterBluePlus.stopScan();
  }

  /// ✅ REMOVE TANK
  void removeTank(Tank tank) {
    _tanks.remove(tank);
    StorageService.saveTanks(_tanks);
    notifyListeners();
  }

  /// ✅ TEST TANK (for debugging)
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
    print('✅ Added test tank: ${newTank.name}');
  }
}