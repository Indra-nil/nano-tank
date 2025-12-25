import 'package:hive/hive.dart';
import '../models/tank.dart';
import '../models/log_record.dart';

class StorageService {
  static Box? _tanksBox;
  static Box? _logsBox;

  static Future<void> init() async {
    _tanksBox = await Hive.openBox('tanks');
    _logsBox = await Hive.openBox('logs');
  }

  // Tank storage
  static List<Tank> getTanks() {
    final List<dynamic> tankData = _tanksBox?.get('tanks', defaultValue: []) ?? [];
    return tankData.map((data) => Tank.fromJson(data)).toList();
  }

  static Future<void> saveTanks(List<Tank> tanks) async {
    await _tanksBox?.put('tanks', tanks.map((t) => t.toJson()).toList());
  }

  static Future<void> saveTank(Tank tank) async {
    final tanks = getTanks();
    final index = tanks.indexWhere((t) => t.id == tank.id);
    if (index != -1) {
      tanks[index] = tank;
    } else {
      tanks.add(tank);
    }
    await saveTanks(tanks);
  }

  // Logs storage
  static Future<void> saveLogs(String tankId, List<LogRecord> logs) async {
    await _logsBox?.put(tankId, logs.map((l) => l.toJson()).toList());
  }

  static List<LogRecord> getLogs(String tankId) {
    final List<dynamic> logData = _logsBox?.get(tankId, defaultValue: []) ?? [];
    return logData.map((data) => LogRecord.fromJson(data)).toList();
  }
}