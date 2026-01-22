import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BleManager extends ChangeNotifier {
  // You can keep this for default name, but scan will not depend on it anymore.
  final String targetDeviceName = "AquariumLED";

  final String serviceUUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String characteristicUUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _characteristic;

  StreamSubscription<List<int>>? _notifySubscription;
  StreamSubscription<List<ScanResult>>? _scanSub;

  // Scan results for manual selection
  final List<ScanResult> _scanResults = [];

  // Remember devices by ID (works even after rename)
  final Set<String> _knownDeviceIds = <String>{};
  static const String _prefsKnownIdsKey = "known_ble_ids";

  // State
  bool _isConnected = false;
  bool _isScanning = false;
  String _status = "Disconnected";

  String _mode = "AUTO";
  int _brightness = 0;
  int _maxBrightness = 100;

  // Timer settings
  int _sunriseDuration = 30; // minutes
  int _sunsetDuration = 30; // minutes
  int _photoStart = 480; // 8:00 AM
  int _photoEnd = 1200; // 8:00 PM

  // CO2 State
  bool _co2Enabled = true;
  int _co2Start = 540; // 9:00 AM
  int _co2End = 1020; // 5:00 PM

  // Time sync
  DateTime? _esp32Time;
  Timer? _timeUpdateTimer;
  bool _showSyncSuccess = false;

  // Getters
  bool get isConnected => _isConnected;
  bool get isScanning => _isScanning;
  String get status => _status;

  String get mode => _mode;
  int get brightness => _brightness;
  int get maxBrightness => _maxBrightness;

  int get sunriseDuration => _sunriseDuration;
  int get sunsetDuration => _sunsetDuration;
  int get photoStart => _photoStart;
  int get photoEnd => _photoEnd;

  bool get co2Enabled => _co2Enabled;
  int get co2Start => _co2Start;
  int get co2End => _co2End;

  BluetoothDevice? get connectedDevice => _connectedDevice;
  DateTime? get esp32Time => _esp32Time;
  bool get showSyncSuccess => _showSyncSuccess;

  List<ScanResult> get scanResults => List.unmodifiable(_scanResults);
  Set<String> get knownDeviceIds => _knownDeviceIds;

  String get formattedEsp32Time {
    if (_esp32Time == null) return "--:--:--";
    return "${_esp32Time!.hour.toString().padLeft(2, '0')}:"
        "${_esp32Time!.minute.toString().padLeft(2, '0')}:"
        "${_esp32Time!.second.toString().padLeft(2, '0')}";
  }

  String get formattedEsp32Date {
    if (_esp32Time == null) return "--/--/----";
    return "${_esp32Time!.day.toString().padLeft(2, '0')}/"
        "${_esp32Time!.month.toString().padLeft(2, '0')}/"
        "${_esp32Time!.year}";
  }

  BleManager() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadKnownIds();

    FlutterBluePlus.adapterState.listen((state) {
      // Keep it passive. User taps Scan.
    });
  }

  Future<void> _loadKnownIds() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_prefsKnownIdsKey) ?? <String>[];
    _knownDeviceIds
      ..clear()
      ..addAll(ids);
  }

  Future<void> _rememberDeviceId(String deviceId) async {
    _knownDeviceIds.add(deviceId);
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_prefsKnownIdsKey) ?? <String>[];
    if (!ids.contains(deviceId)) {
      ids.add(deviceId);
      await prefs.setStringList(_prefsKnownIdsKey, ids);
    }
  }

  // ========= SCAN =========

  Future<void> startScan() async {
    if (_isScanning) return;

    _scanResults.clear();
    _isScanning = true;
    _status = "Scanning...";
    notifyListeners();

    try {
      await _scanSub?.cancel();
      _scanSub = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          final name = (r.device.platformName).toLowerCase();
          final id = r.device.remoteId.str;

          // Show devices if:
          // 1) Name contains "aquarium" (good for first-time), OR
          // 2) Device ID already known (works after rename to anything)
          final matches = name.contains("aquarium") || _knownDeviceIds.contains(id);
          if (!matches) continue;

          final already = _scanResults.any((x) => x.device.remoteId == r.device.remoteId);
          if (!already) {
            _scanResults.add(r);
            notifyListeners();
          }
        }
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    } catch (e) {
      _status = "Scan failed: $e";
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  // ========= CONNECT =========

  Future<void> connectToDevice(ScanResult result) async {
    final device = result.device;

    try {
      await disconnect(); // cleanup old
      await device.connect();

      _connectedDevice = device;
      _isConnected = true;
      _status = "Connected to ${device.platformName}";
      notifyListeners();

      // Save this device ID so rename won't break future scans
      await _rememberDeviceId(device.remoteId.str);

      final services = await device.discoverServices();
      for (final service in services) {
        if (service.uuid.toString() != serviceUUID) continue;

        for (final ch in service.characteristics) {
          if (ch.uuid.toString() != characteristicUUID) continue;

          _characteristic = ch;
          await _characteristic!.setNotifyValue(true);

          await _notifySubscription?.cancel();
          _notifySubscription = _characteristic!.value.listen((value) {
            if (value.isEmpty) return;
            final data = String.fromCharCodes(value);
            _parseIncomingData(data);
            _parseTimeMessage(data);
          });

          _initializeTimeTimer();

          _sendCommand("GET_STATUS");
          _sendCommand("GET_TIMERS");
          _sendCommand("GET_CO2");
          _sendCommand("GET_TIME");
          return;
        }
      }

      _status = "Service/Characteristic not found";
      notifyListeners();
    } catch (e) {
      _status = "Connection failed: $e";
      _isConnected = false;
      notifyListeners();
    }
  }

  void _initializeTimeTimer() {
    _timeUpdateTimer?.cancel();
    _timeUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_esp32Time != null && _isConnected) {
        _esp32Time = _esp32Time!.add(const Duration(seconds: 1));
        notifyListeners();

        if (timer.tick % 30 == 0) {
          _sendCommand("GET_TIME");
        }
      }
    });
  }

  // ========= PARSING =========

  void _parseIncomingData(String data) {
    // Status: MODE:AUTO,BRIGHT:45,MAX:75
    if (data.contains("MODE:") && data.contains("BRIGHT:") && data.contains("MAX:")) {
      try {
        final parts = data.split(',');
        for (final part in parts) {
          if (part.startsWith("MODE:")) {
            final esp32Mode = part.substring(5);
            if (esp32Mode == "AUTO") {
              _mode = "AUTO";
            } else if (esp32Mode == "MANUAL") {
              // derive nice label based on brightness
              if (_brightness == 0) {
                _mode = "OFF";
              } else if (_brightness > 80 && _brightness <= 100) {
                _mode = "DAY";
              } else if (_brightness > 0 && _brightness <= 5) {
                _mode = "NIGHT";
              } else {
                _mode = "ON";
              }
            }
          } else if (part.startsWith("BRIGHT:")) {
            _brightness = int.tryParse(part.substring(7)) ?? 0;
          } else if (part.startsWith("MAX:")) {
            _maxBrightness = int.tryParse(part.substring(4)) ?? 100;
          }
        }
      } catch (_) {}
    } else if (data.contains("MODE:") && data.contains("BRI:")) {
      // old format
      _mode = data.split("MODE:")[1].split(",")[0];
      _brightness = int.tryParse(data.split("BRI:")[1]) ?? 0;
    }

    // Timers: START:480,END:1200,RISE:30,SET:30
    if (data.startsWith("START:") && data.contains("RISE:") && data.contains("SET:")) {
      try {
        final parts = data.split(',');
        for (final part in parts) {
          if (part.startsWith("START:")) {
            _photoStart = int.tryParse(part.substring(6)) ?? 480;
          } else if (part.startsWith("END:")) {
            _photoEnd = int.tryParse(part.substring(4)) ?? 1200;
          } else if (part.startsWith("RISE:")) {
            _sunriseDuration = int.tryParse(part.substring(5)) ?? 30;
          } else if (part.startsWith("SET:")) {
            _sunsetDuration = int.tryParse(part.substring(4)) ?? 30;
          }
        }
      } catch (_) {}
    }

    // CO2: CO2:STATUS:ON,START:540,END:1020
    if (data.startsWith("CO2:STATUS:")) {
      try {
        final parts = data.split(',');
        for (final part in parts) {
          if (part.startsWith("CO2:STATUS:")) {
            _co2Enabled = part.substring(11) == "ON";
          } else if (part.startsWith("START:")) {
            _co2Start = int.tryParse(part.substring(6)) ?? 540;
          } else if (part.startsWith("END:")) {
            _co2End = int.tryParse(part.substring(4)) ?? 1020;
          }
        }
      } catch (_) {}
    }

    notifyListeners();
  }

  void _parseTimeMessage(String data) {
    if (data.startsWith("TIME:")) {
      final timeStr = data.substring(5);
      final parts = timeStr.split(',');
      if (parts.length == 2) {
        final dateParts = parts[0].split('-');
        final timeParts = parts[1].split(':');
        if (dateParts.length == 3 && timeParts.length == 3) {
          try {
            _esp32Time = DateTime(
              int.parse(dateParts[0]),
              int.parse(dateParts[1]),
              int.parse(dateParts[2]),
              int.parse(timeParts[0]),
              int.parse(timeParts[1]),
              int.parse(timeParts[2]),
            );
            notifyListeners();
          } catch (_) {}
        }
      }
    } else if (data.startsWith("CURRENT_TIME:")) {
      final timeStr = data.substring(13);
      final parts = timeStr.split(':');
      if (parts.length == 6) {
        try {
          _esp32Time = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
            int.parse(parts[3]),
            int.parse(parts[4]),
            int.parse(parts[5]),
          );
          notifyListeners();
        } catch (_) {}
      }
    } else if (data.startsWith("TIME_SET:")) {
      _showSyncSuccess = true;
      notifyListeners();
      Timer(const Duration(seconds: 3), () {
        _showSyncSuccess = false;
        notifyListeners();
      });
      _sendCommand("GET_TIME");
    }
  }

  // ========= COMMANDS =========

  Future<void> _sendCommand(String command) async {
    if (_characteristic != null && _isConnected) {
      try {
        await _characteristic!.write(command.codeUnits);
      } catch (_) {}
    }
  }

  void setBrightness(int percent) {
    percent = percent.clamp(0, 100);
    _brightness = percent;
    _sendCommand("BRIGHT:$percent");
    notifyListeners();
  }

  void setMaxBrightness(int percent) {
    percent = percent.clamp(0, 100);
    _maxBrightness = percent;
    _sendCommand("SET:$percent");
    notifyListeners();
  }

  void setMode(String modeCommand) {
    _mode = modeCommand;
    _sendCommand(modeCommand);
    notifyListeners();
  }

  void setSunriseDuration(int minutes) {
    minutes = minutes.clamp(0, 240);
    _sunriseDuration = minutes;
    _sendCommand("SUNRISE_DUR:$minutes");
    notifyListeners();
  }

  void setSunsetDuration(int minutes) {
    minutes = minutes.clamp(0, 240);
    _sunsetDuration = minutes;
    _sendCommand("SUNSET_DUR:$minutes");
    notifyListeners();
  }

  void setPhotoperiodStart(int minutesFromMidnight) {
    minutesFromMidnight = minutesFromMidnight.clamp(0, 1439);
    _photoStart = minutesFromMidnight;
    _sendCommand("PHOTO_START:$minutesFromMidnight");
    notifyListeners();
  }

  void setPhotoperiodEnd(int minutesFromMidnight) {
    minutesFromMidnight = minutesFromMidnight.clamp(0, 1439);
    _photoEnd = minutesFromMidnight;
    _sendCommand("PHOTO_END:$minutesFromMidnight");
    notifyListeners();
  }

  void setCO2Enabled(bool enabled) {
    _co2Enabled = enabled;
    _sendCommand(enabled ? "CO2_ON" : "CO2_OFF");
    notifyListeners();
  }

  void setCO2Start(int minutesFromMidnight) {
    minutesFromMidnight = minutesFromMidnight.clamp(0, 1439);
    _co2Start = minutesFromMidnight;
    _sendCommand("CO2_START:$minutesFromMidnight");
    notifyListeners();
  }

  void setCO2End(int minutesFromMidnight) {
    minutesFromMidnight = minutesFromMidnight.clamp(0, 1439);
    _co2End = minutesFromMidnight;
    _sendCommand("CO2_END:$minutesFromMidnight");
    notifyListeners();
  }

  void requestCO2Status() => _sendCommand("GET_CO2");
  void saveAllSettings() => _sendCommand("SAVE_ALL");
  void sendCommand(String command) => _sendCommand(command);

  Future<void> syncTimeFromPhone() async {
    final now = DateTime.now();
    final cmd = "SET_TIME:"
        "${now.year.toString().padLeft(4, '0')}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.day.toString().padLeft(2, '0')},"
        "${now.hour.toString().padLeft(2, '0')}:"
        "${now.minute.toString().padLeft(2, '0')}:"
        "${now.second.toString().padLeft(2, '0')}";
    await _sendCommand(cmd);
  }

  Future<void> requestEsp32Time() async => _sendCommand("GET_TIME");

  Future<void> renameDevice(String newName) async {
    await _sendCommand("RENAME:$newName");
  }

  Future<void> reconnect() async {
    if (!_isConnected && !_isScanning) {
      await startScan();
    }
  }

  Future<void> disconnect() async {
    try {
      await _notifySubscription?.cancel();
      _timeUpdateTimer?.cancel();
      await _connectedDevice?.disconnect();
    } catch (_) {}

    _connectedDevice = null;
    _characteristic = null;
    _isConnected = false;
    _status = "Disconnected";
    _esp32Time = null;

    _notifySubscription = null;
    _timeUpdateTimer = null;

    // Reset UI defaults
    _mode = "AUTO";
    _brightness = 0;
    _maxBrightness = 100;

    _sunriseDuration = 30;
    _sunsetDuration = 30;
    _photoStart = 480;
    _photoEnd = 1200;

    _co2Enabled = true;
    _co2Start = 540;
    _co2End = 1020;

    notifyListeners();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _notifySubscription?.cancel();
    _timeUpdateTimer?.cancel();
    disconnect();
    super.dispose();
  }
}