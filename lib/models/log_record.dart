class LogRecord {
  final DateTime time;
  final double ph;
  final double tds;
  final double temp;

  LogRecord({
    required this.time,
    required this.ph,
    required this.tds,
    required this.temp,
  });

  Map<String, dynamic> toJson() => {
    'time': time.millisecondsSinceEpoch,
    'ph': ph,
    'tds': tds,
    'temp': temp,
  };

  factory LogRecord.fromJson(Map<String, dynamic> json) {
    return LogRecord(
      time: DateTime.fromMillisecondsSinceEpoch(json['time']),
      ph: json['ph']?.toDouble() ?? 0.0,
      tds: json['tds']?.toDouble() ?? 0.0,
      temp: json['temp']?.toDouble() ?? 0.0,
    );
  }
}