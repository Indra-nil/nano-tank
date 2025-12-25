class TankConfig {
  String photosynthesisStart;
  String photoperiodDuration;
  double co2TargetPH;
  double sunsetPHThreshold;
  double lightSunriseDurationMin;
  double lightSunsetDurationMin;
  int lightFullDuty;
  int co2HoldDuty;
  int co2StartDuty;
  List<PumpConfig> pumps;

  // ✅ DEFAULT CONSTRUCTOR - FIXES ALL ERRORS
  TankConfig({
    this.photosynthesisStart = '08:00',
    this.photoperiodDuration = '8h',
    this.co2TargetPH = 6.0,
    this.sunsetPHThreshold = 6.5,
    this.lightSunriseDurationMin = 30.0,
    this.lightSunsetDurationMin = 30.0,
    this.lightFullDuty = 255,
    this.co2HoldDuty = 80,
    this.co2StartDuty = 255,
    List<PumpConfig>? pumps,
  }) : pumps = pumps ?? List.generate(4, (i) => PumpConfig(id: i));

  Map<String, dynamic> toJson() => {
    'photosynthesisStart': photosynthesisStart,
    'photoperiodDuration': photoperiodDuration,
    'co2TargetPH': co2TargetPH,
    'sunsetPHThreshold': sunsetPHThreshold,
    'lightSunriseDurationMin': lightSunriseDurationMin,
    'lightSunsetDurationMin': lightSunsetDurationMin,
    'lightFullDuty': lightFullDuty,
    'co2HoldDuty': co2HoldDuty,
    'co2StartDuty': co2StartDuty,
    'pumps': pumps.map((p) => p.toJson()).toList(),
  };

  factory TankConfig.fromJson(Map<String, dynamic> json) => TankConfig(
    photosynthesisStart: json['photosynthesisStart'] ?? '08:00',
    photoperiodDuration: json['photoperiodDuration'] ?? '8h',
    co2TargetPH: (json['co2TargetPH'] ?? 6.0).toDouble(),
    sunsetPHThreshold: (json['sunsetPHThreshold'] ?? 6.5).toDouble(),
    lightSunriseDurationMin: (json['lightSunriseDurationMin'] ?? 30.0).toDouble(),
    lightSunsetDurationMin: (json['lightSunsetDurationMin'] ?? 30.0).toDouble(),
    lightFullDuty: json['lightFullDuty'] ?? 255,
    co2HoldDuty: json['co2HoldDuty'] ?? 80,
    co2StartDuty: json['co2StartDuty'] ?? 255,
    pumps: (json['pumps'] as List?)
        ?.map((e) => PumpConfig.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class PumpConfig {
  final int id;
  String name;
  bool enabled;
  double mlPerSec;
  double containerMl;
  double remainingMl;
  List<double> dailyDoseMl;
  int dosesPerDay;
  DateTime? nextDose;

  PumpConfig({
    required this.id,
    this.name = '',
    this.enabled = false,
    this.mlPerSec = 0.0,
    this.containerMl = 500.0,
    this.remainingMl = 500.0,
    List<double>? dailyDoseMl,
    this.dosesPerDay = 4,
    this.nextDose,
  }) : dailyDoseMl = dailyDoseMl ?? List.filled(7, 0.0);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'enabled': enabled,
    'mlPerSec': mlPerSec,
    'containerMl': containerMl,
    'remainingMl': remainingMl,
    'dailyDoseMl': dailyDoseMl,
    'dosesPerDay': dosesPerDay,
    'nextDose': nextDose?.millisecondsSinceEpoch,
  };

  factory PumpConfig.fromJson(Map<String, dynamic> json) => PumpConfig(
    id: json['id'] ?? 0,
    name: json['name'] ?? 'Pump ${(json['id'] ?? 0) + 1}',
    enabled: json['enabled'] ?? false,
    mlPerSec: (json['mlPerSec'] ?? 0.0).toDouble(),
    containerMl: (json['containerMl'] ?? 500.0).toDouble(),
    remainingMl: (json['remainingMl'] ?? 500.0).toDouble(),
    dailyDoseMl: List<double>.from(json['dailyDoseMl'] ?? List.filled(7, 0.0)),
    dosesPerDay: json['dosesPerDay'] ?? 4,
    nextDose: json['nextDose'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(json['nextDose'])
        : null,
  );
}