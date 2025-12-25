import 'package:flutter/material.dart';
import 'package:flutter/services.dart';  // ✅ Clipboard import
import 'package:fl_chart/fl_chart.dart';
import '../models/tank.dart';
import '../widgets/glass_card.dart';

class DataScreen extends StatefulWidget {
  final Tank tank;
  const DataScreen({Key? key, required this.tank}) : super(key: key);

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  String selectedTimeRange = '24h'; // 24h, 7d, 30d, all
  String selectedParameter = 'ph'; // ph, tds, temp
  
  // Mock data for different ranges
  final Map<String, List<FlSpot>> phData = {
    '24h': List.generate(24, (i) => FlSpot(i.toDouble(), 6.8 + (i * 0.05) % 0.5)),
    '7d': List.generate(7, (i) => FlSpot(i.toDouble(), 7.0 + (i * 0.08) % 0.6)),
    '30d': List.generate(30, (i) => FlSpot(i.toDouble(), 7.1 + (i * 0.03) % 0.8)),
  };

  final Map<String, List<FlSpot>> tdsData = {
    '24h': List.generate(24, (i) => FlSpot(i.toDouble(), 400 + (i * 5) % 100)),
    '7d': List.generate(7, (i) => FlSpot(i.toDouble(), 420 + (i * 8) % 80)),
    '30d': List.generate(30, (i) => FlSpot(i.toDouble(), 450 + (i * 4) % 120)),
  };

  final Map<String, List<FlSpot>> tempData = {
    '24h': List.generate(24, (i) => FlSpot(i.toDouble(), 24.0 + (i * 0.1) % 2.0)),
    '7d': List.generate(7, (i) => FlSpot(i.toDouble(), 23.8 + (i * 0.2) % 2.5)),
    '30d': List.generate(30, (i) => FlSpot(i.toDouble(), 24.2 + (i * 0.08) % 3.0)),
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          // ✅ LIVE READINGS
          GlassCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _LiveReading('pH', '7.2', Colors.cyan),
                    _LiveReading('TDS', '450 ppm', Colors.green),
                    _LiveReading('Temp', '24.5°C', Colors.orange),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          // ✅ TIME RANGE SELECTOR
          Text('Time Range:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['24h', '7d', '30d'].map((range) {
                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(range),
                    selected: selectedTimeRange == range,
                    onSelected: (selected) => setState(() => selectedTimeRange = range),
                    selectedColor: Colors.cyan.withOpacity(0.3),
                    checkmarkColor: Colors.cyan,
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 20),

          // ✅ PARAMETER SELECTOR
          Text('Parameter:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ('pH', 'ph', Colors.cyan),
                ('TDS', 'tds', Colors.green),
                ('Temp', 'temp', Colors.orange),
              ].map((param) {
                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(param.$1),
                    selected: selectedParameter == param.$2,
                    onSelected: (selected) => setState(() => selectedParameter = param.$2),
                    selectedColor: param.$3.withOpacity(0.3),
                    checkmarkColor: param.$3,
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 20),

          // ✅ STATISTICS
          GlassCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Statistic('Min', _getMinValue(), Colors.blue),
                _Statistic('Avg', _getAvgValue(), Colors.purple),
                _Statistic('Max', _getMaxValue(), Colors.red),
              ],
            ),
          ),
          SizedBox(height: 20),

          // ✅ GRAPH
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_getParameterTitle()} History - $selectedTimeRange',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(Icons.download, color: Colors.cyan),
                      onPressed: _exportData,
                      tooltip: 'Export CSV',
                    ),
                  ],
                ),
                SizedBox(height: 20),
                SizedBox(
                  height: 250,
                  child: LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: _getChartData(),
                          isCurved: true,
                          color: _getParameterColor(),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: _getParameterColor().withOpacity(0.2),
                          ),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}',
                                style: TextStyle(fontSize: 10, color: Colors.white70),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toStringAsFixed(1)}',
                                style: TextStyle(fontSize: 10, color: Colors.white70),
                              );
                            },
                            reservedSize: 40,
                          ),
                        ),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _getHorizontalInterval(),
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.white.withOpacity(0.1),
                            strokeWidth: 1,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          // ✅ EXPORT BUTTON
          ElevatedButton.icon(
            onPressed: _exportData,
            icon: Icon(Icons.download),
            label: Text('Export Data as CSV'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 56),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _getChartData() {
    switch (selectedParameter) {
      case 'ph':
        return phData[selectedTimeRange] ?? [];
      case 'tds':
        return tdsData[selectedTimeRange] ?? [];
      case 'temp':
        return tempData[selectedTimeRange] ?? [];
      default:
        return [];
    }
  }

  Color _getParameterColor() {
    switch (selectedParameter) {
      case 'ph':
        return Colors.cyan;
      case 'tds':
        return Colors.green;
      case 'temp':
        return Colors.orange;
      default:
        return Colors.cyan;
    }
  }

  String _getParameterTitle() {
    switch (selectedParameter) {
      case 'ph':
        return 'pH';
      case 'tds':
        return 'TDS (ppm)';
      case 'temp':
        return 'Temperature (°C)';
      default:
        return '';
    }
  }

  double _getMinValue() {
    final data = _getChartData();
    if (data.isEmpty) return 0.0;
    return data.map((e) => e.y).reduce((a, b) => a < b ? a : b);
  }

  double _getAvgValue() {
    final data = _getChartData();
    if (data.isEmpty) return 0.0;
    return data.map((e) => e.y).reduce((a, b) => a + b) / data.length;
  }

  double _getMaxValue() {
    final data = _getChartData();
    if (data.isEmpty) return 0.0;
    return data.map((e) => e.y).reduce((a, b) => a > b ? a : b);
  }

  double _getHorizontalInterval() {
    switch (selectedParameter) {
      case 'ph':
        return 0.2;
      case 'tds':
        return 50;
      case 'temp':
        return 1.0;
      default:
        return 1.0;
    }
  }

  // ✅ OPTION 2: Copy to Clipboard
  void _exportData() {
    final data = _getChartData();
    final title = _getParameterTitle();
    
    String csv = '$title,$selectedTimeRange\nTime,Value\n';
    for (var i = 0; i < data.length; i++) {
      csv += '${data[i].x.toStringAsFixed(0)},${data[i].y.toStringAsFixed(2)}\n';
    }
    
    Clipboard.setData(ClipboardData(text: csv));  // ✅ COPY TO CLIPBOARD
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📋 $title data copied! ($selectedTimeRange)'),
        duration: Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Dismiss',
          onPressed: () {},
        ),
      ),
    );
  }
}

class _LiveReading extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _LiveReading(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.white70)),
      ],
    );
  }
}

class _Statistic extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _Statistic(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white70)),
        SizedBox(height: 4),
        Text(
          value.toStringAsFixed(2),
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}