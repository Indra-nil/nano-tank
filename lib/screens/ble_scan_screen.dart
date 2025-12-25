import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import '../providers/tank_provider.dart';
import '../services/ble_service.dart';

class BleScanScreen extends StatefulWidget {
  @override
  _BleScanScreenState createState() => _BleScanScreenState();
}

class _BleScanScreenState extends State<BleScanScreen> {
  final Map<String, ScanResult> _foundDevices = {};
  StreamSubscription<List<ScanResult>>? _subscription;
  bool _isScanning = false;

  List<ScanResult> get _nanoTankDevices => _foundDevices.values
      .where((result) => _isNanoTank(result))
      .toList()
    ..sort((a, b) => b.rssi.compareTo(a.rssi));

  bool _isNanoTank(ScanResult result) {
    final name = result.device.platformName.toLowerCase();
    final id = result.device.remoteId.str.toLowerCase();
    return name.contains('tank') ||
        name.contains('controller') ||
        name.contains('esp') ||
        name.contains('nano') ||
        id.contains('tank');
  }

  @override
  void dispose() {
    _subscription?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final devices = _nanoTankDevices;

    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Nano Tanks'),
        backgroundColor: Colors.teal,
        actions: [
          TextButton(
            onPressed: _isScanning ? null : _startScan,
            child: Text(_isScanning ? 'SCANNING...' : 'SCAN'),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ STATUS BAR
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.teal.withOpacity(0.1),
            child: Row(
              children: [
                Icon(_isScanning ? Icons.search : Icons.search_off,
                    color: _isScanning ? Colors.green : Colors.grey, size: 24),
                SizedBox(width: 12),
                Expanded(child: Text('${devices.length} Nano Tanks found')),
                if (_isScanning)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
              ],
            ),
          ),
          
          // ✅ FILTER INFO
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.green.withOpacity(0.1),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.green, size: 18),
                SizedBox(width: 8),
                //Expanded(child: Text('TankController, ESP32, NanoTank, Controller')),
              ],
            ),
          ),
          
          Expanded(
            child: devices.isEmpty && !_isScanning
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.water, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No Nano Tanks found', style: TextStyle(fontSize: 18)),
                        SizedBox(height: 8),
                        Text('Make sure your TankController is powered on\nand advertising as "TankController"', 
                             textAlign: TextAlign.center,
                             style: TextStyle(fontSize: 14, color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      final name = device.device.platformName.isEmpty
                          ? 'Tank ${device.device.remoteId.str.substring(0, 8)}'
                          : device.device.platformName;
                      
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        color: Colors.green.withOpacity(0.05),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Text('${device.rssi}dB', 
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(name, 
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          subtitle: Text('Signal: ${device.rssi}dBm\nID: ${device.device.remoteId.str}'),
                          trailing: Icon(Icons.arrow_forward_ios, color: Colors.green, size: 20),
                          onTap: () => _addTank(device),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// 🔥 ULTIMATE SCAN - Android 12+ Compatible
  Future<void> _startScan() async {
    print('🔍 === NANO TANK SCAN START ===');
    
    // Stop previous scan
    await FlutterBluePlus.stopScan();
    await _subscription?.cancel();
    
    setState(() {
      _isScanning = true;
      _foundDevices.clear();
    });
    
    // Permissions
    try {
      await BleService.requestPermissions();
    } catch (e) {
      setState(() => _isScanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Permission error: $e'), backgroundColor: Colors.red),
      );
      return;
    }
    
    // Listen FIRST
    _subscription = FlutterBluePlus.scanResults.listen((batch) {
      print('🔍 Batch: ${batch.length} devices');
      for (var result in batch) {
        final key = result.device.remoteId.str;
        _foundDevices[key] = result; // Update with latest RSSI
        if (_isNanoTank(result)) {
          print('🟢 NANO TANK: "${result.device.platformName}" (${result.rssi}dBm)');
        }
      }
      setState(() {});
    });
    
    // Start scan - Android 12+ optimized
    await FlutterBluePlus.startScan(
      timeout: Duration(seconds: 20),
      androidUsesFineLocation: true,
      androidScanMode: AndroidScanMode.lowLatency,
    );
    
    // Auto-stop
    await Future.delayed(Duration(seconds: 20));
    await FlutterBluePlus.stopScan();
    await _subscription?.cancel();
    setState(() => _isScanning = false);
    
    print('🔍 Scan complete: ${_nanoTankDevices.length} Nano Tanks');
  }

  void _addTank(ScanResult device) {
    final provider = Provider.of<TankProvider>(context, listen: false);
    final name = device.device.platformName.isEmpty 
        ? 'Nano Tank' : device.device.platformName;
    
    provider.scanAndAddTankWithId(context, device.device.remoteId.str);
    
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ $name added! ${device.rssi}dBm'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }
}