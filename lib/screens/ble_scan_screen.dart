import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import '../providers/tank_provider.dart';

class BleScanScreen extends StatefulWidget {
  const BleScanScreen({super.key});

  @override
  State<BleScanScreen> createState() => _BleScanScreenState();
}

class _BleScanScreenState extends State<BleScanScreen> {
  final Map<String, ScanResult> _foundDevices = {};
  StreamSubscription<List<ScanResult>>? _subscription;
  bool _isScanning = false;

  List<ScanResult> get _nanoTankDevices =>
      _foundDevices.values.where(_isNanoTank).toList()
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
        title: const Text('Scan Nano Tanks'),
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
          _statusBar(devices.length),
          Expanded(child: _deviceList(devices)),
        ],
      ),
    );
  }

  Widget _statusBar(int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.teal.withOpacity(0.1),
      child: Row(
        children: [
          Icon(
            _isScanning ? Icons.search : Icons.search_off,
            color: _isScanning ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text('$count Nano Tanks found')),
          if (_isScanning)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _deviceList(List<ScanResult> devices) {
    if (devices.isEmpty && !_isScanning) {
      return const Center(
        child: Text(
          'No Nano Tanks found\nPower ON your controller',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final device = devices[index];
        final name = device.device.platformName.isEmpty
            ? 'Nano Tank'
            : device.device.platformName;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green,
              child: Text(
                '${device.rssi}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(device.device.remoteId.str),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _addTank(device),
          ),
        );
      },
    );
  }

  /// 🔍 START SCAN
  Future<void> _startScan() async {
    await FlutterBluePlus.stopScan();
    await _subscription?.cancel();

    setState(() {
      _isScanning = true;
      _foundDevices.clear();
    });

    _subscription = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        _foundDevices[r.device.remoteId.str] = r;
      }
      setState(() {});
    });

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 20),
      androidScanMode: AndroidScanMode.lowLatency,
    );

    await Future.delayed(const Duration(seconds: 20));
    await FlutterBluePlus.stopScan();
    await _subscription?.cancel();

    setState(() => _isScanning = false);
  }

  /// ✅ CONNECT + NAVIGATE (FIXED)
  Future<void> _addTank(ScanResult device) async {
    final provider = Provider.of<TankProvider>(context, listen: false);

    // ⏳ Loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await provider.scanAndAddTankWithId(
        context,
        device.device.remoteId.str,
      );

      if (!mounted) return;

      Navigator.pop(context); // close loader

      // 🔥 GO TO HOME / DASHBOARD
      Navigator.pop(context); // close scan screen
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Connection failed: $e')),
      );
    }
  }
}