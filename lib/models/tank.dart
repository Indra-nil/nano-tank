import 'config.dart';
import 'log_record.dart';

class Tank {
  final String id;
  String name;
  final String bleDeviceId;
  bool connected;
  LiveData liveData;
  TankConfig tankConfig;
  final List<LogRecord> history;
  int lowPumps;

  Tank({
    required this.id,
    required this.name,
    required this.bleDeviceId,
    this.connected = false,
    LiveData? liveDataParam,
    TankConfig? tankConfigParam,
    List<LogRecord>? historyParam,
    this.lowPumps = 0,
  })  : liveData = liveDataParam ?? LiveData(),
        tankConfig = tankConfigParam ?? TankConfig(),
        history = historyParam ?? [];

  int get activePumps => tankConfig.pumps.where((p) => p.enabled).length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bleDeviceId': bleDeviceId,
        'connected': connected,
        'liveData': liveData.toJson(),
        'tankConfig': tankConfig.toJson(),
        'history': history.map((h) => h.toJson()).toList(),
        'lowPumps': lowPumps,
      };

  factory Tank.fromJson(Map<String, dynamic> json) => Tank(
        id: json['id'] ?? '',
        name: json['name'] ?? 'Unknown',
        bleDeviceId: json['bleDeviceId'] ?? '',
        connected: json['connected'] ?? false,
        lowPumps: json['lowPumps'] ?? 0,
      );
}

class LiveData {
  double? ph, tds, temp, vcc;
  String state;
  Map<String, bool> pumpStatus;

  LiveData({
    this.ph,
    this.tds,
    this.temp,
    this.vcc,
    this.state = 'NIGHT',
    Map<String, bool>? pumpStatus,
  }) : pumpStatus = pumpStatus ?? {};

  Map<String, dynamic> toJson() => {
        'ph': ph,
        'tds': tds,
        'temp': temp,
        'vcc': vcc,
        'state': state,
        'pumpStatus': pumpStatus,
      };

  factory LiveData.fromJson(Map<String, dynamic> json) => LiveData(
        ph: json['ph']?.toDouble(),
        tds: json['tds']?.toDouble(),
        temp: json['temp']?.toDouble(),
        vcc: json['vcc']?.toDouble(),
        state: json['state'] ?? 'NIGHT',
        pumpStatus: Map<String, bool>.from(json['pumpStatus'] ?? {}),
      );
}