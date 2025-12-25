import 'package:flutter/material.dart';
import '../models/tank.dart';
import '../widgets/glass_card.dart';

class Co2Screen extends StatelessWidget {
  final Tank tank;
  const Co2Screen({Key? key, required this.tank}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ✅ Mock CO2 data with proper types
    final mockCo2Data = {
      'co2TargetPH': 6.5,
      'state': 'ON',
      'ph': 6.8,
    };

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          GlassCard(
            child: Column(
              children: [
                Icon(Icons.whatshot, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text('CO₂ Control', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text('Target pH: ${(mockCo2Data['co2TargetPH'] as double).toStringAsFixed(1)}'),  // ✅ FIXED
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _Co2StatusCard(tank: tank, co2Data: mockCo2Data),
                    _Co2SettingsCard(tank: tank, co2Data: mockCo2Data),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Co2StatusCard extends StatelessWidget {
  final Tank tank;
  final Map<String, dynamic> co2Data;
  
  const _Co2StatusCard({Key? key, required this.tank, required this.co2Data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isCo2On = co2Data['state'] == 'ON';
    final currentPh = (co2Data['ph'] as double?) ?? 7.0;  // ✅ SAFE CAST + fallback

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isCo2On ? Colors.red.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.whatshot, size: 48, color: Colors.white),
        ),
        SizedBox(height: 12),
        Text(co2Data['state'].toString(), style: TextStyle(fontWeight: FontWeight.w600)),
        Text('pH ${currentPh.toStringAsFixed(1)}'),  // ✅ PERFECT
      ],
    );
  }
}

class _Co2SettingsCard extends StatelessWidget {
  final Tank tank;
  final Map<String, dynamic> co2Data;
  
  const _Co2SettingsCard({Key? key, required this.tank, required this.co2Data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final targetPh = (co2Data['co2TargetPH'] as double?) ?? 6.5;  // ✅ SAFE CAST

    return Column(
      children: [
        Icon(Icons.settings, size: 48, color: Colors.cyan),
        SizedBox(height: 12),
        Text('Settings', style: TextStyle(fontWeight: FontWeight.w600)),
        SizedBox(height: 8),
        Text('Target: ${targetPh.toStringAsFixed(1)} pH'),  // ✅ PERFECT
        SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => _showCo2Settings(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyan,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: Text('Edit'),
        ),
      ],
    );
  }

  void _showCo2Settings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('CO₂ Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Target pH: 6.5'),
            SizedBox(height: 8),
            Text('On: 8:00 AM - 6:00 PM'),
            SizedBox(height: 8),
            Text('Bubble rate: Medium'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('CO₂ settings saved! ✅')),
              );
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
}