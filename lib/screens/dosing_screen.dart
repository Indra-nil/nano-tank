import 'package:flutter/material.dart';
import '../models/tank.dart';
import '../widgets/glass_card.dart';
import 'pump_setup_screen.dart';  // ✅ NEW: Pump setup import

class DosingScreen extends StatelessWidget {
  final Tank tank;
  
  const DosingScreen({Key? key, required this.tank}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Mock pumps data
    final mockPumps = [
      Pump(name: 'K+ (Potassium)', remainingMl: 450, enabled: true),
      Pump(name: 'Fe (Iron)', remainingMl: 120, enabled: true),
      Pump(name: 'NO3 (Nitrate)', remainingMl: 800, enabled: false),
      Pump(name: 'PO4 (Phosphate)', remainingMl: 300, enabled: true),
    ];

    return Scaffold(  // ✅ WRAPPED in Scaffold
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: mockPumps
              .where((p) => p.enabled)
              .map((pump) => GlassCard(
                    margin: EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: _getPumpStatusColor(pump),
                              child: Icon(Icons.water_drop),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(pump.name, style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text('${pump.remainingMl.toStringAsFixed(0)}ml (${_daysLeft(pump).toStringAsFixed(0)}d)'),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Text('Next: 14:30'),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    _QuickDoseButton(pump: pump),
                                    SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () => _showSchedule(context, pump),
                                      child: Text('Schedule'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
      // ✅ NEW: Floating Action Button for NEW PUMP
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PumpSetupScreen(tank: tank),
          ),
        ),
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.cyan,
        tooltip: 'Add New Pump',
      ),
    );
  }

  Color _getPumpStatusColor(Pump pump) {
    if (pump.remainingMl < 50) return Colors.red;
    if (pump.remainingMl < 200) return Colors.orange;
    return Colors.green;
  }

  double _daysLeft(Pump pump) {
    return pump.remainingMl / 50;  // Mock: 50ml/day usage
  }

  void _showSchedule(BuildContext context, Pump pump) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Schedule ${pump.name}'),
        content: Text('Configure dosing schedule'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Close')),
        ],
      ),
    );
  }
}

class _QuickDoseButton extends StatelessWidget {
  final Pump pump;
  
  const _QuickDoseButton({Key? key, required this.pump}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: ElevatedButton(
        onPressed: () => _showQuickDoseDialog(context, pump),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.cyan,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: EdgeInsets.zero,
        ),
        child: Icon(Icons.flash_on, size: 20),
      ),
    );
  }

  void _showQuickDoseDialog(BuildContext context, Pump pump) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Quick Dose'),
        content: Text('Dose 5ml of ${pump.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Dosed ${pump.name}! 💧')),
              );
            },
            child: Text('Dose'),
          ),
        ],
      ),
    );
  }
}

class Pump {
  final String name;
  final double remainingMl;
  final bool enabled;

  Pump({required this.name, required this.remainingMl, required this.enabled});
}