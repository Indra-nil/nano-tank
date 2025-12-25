import 'package:flutter/material.dart';
import '../models/tank.dart';
import '../widgets/glass_card.dart';

class LightScreen extends StatelessWidget {
  final Tank tank;
  
  const LightScreen({Key? key, required this.tank}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          GlassCard(
            child: Column(
              children: [
                Icon(Icons.lightbulb, size: 64, color: Colors.amber),
                SizedBox(height: 16),
                Text('Photoperiod', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text('8:00 AM - 4:00 PM', style: TextStyle(fontSize: 16, color: Colors.white70)),
              ],
            ),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: GlassCard(child: _SunriseCard(tank: tank))),
              SizedBox(width: 16),
              Expanded(child: GlassCard(child: _SunsetCard(tank: tank))),  // ✅ FIXED: Complete class
            ],
          ),
        ],
      ),
    );
  }
}

class _SunriseCard extends StatelessWidget {
  final Tank tank;
  const _SunriseCard({Key? key, required this.tank}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.trending_up, color: Colors.orange),
        Text('Sunrise', style: TextStyle(fontWeight: FontWeight.w600)),
        Text('30 min', style: TextStyle(color: Colors.white70)),
        SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => _showTimePicker(context, 'Sunrise'),  // ✅ FIXED: Defined below
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.withOpacity(0.2),
            foregroundColor: Colors.orange,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text('Edit'),
        ),
      ],
    );
  }
}

class _SunsetCard extends StatelessWidget {  // ✅ COMPLETE CLASS
  final Tank tank;
  const _SunsetCard({Key? key, required this.tank}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.trending_down, color: Colors.purple),
        Text('Sunset', style: TextStyle(fontWeight: FontWeight.w600)),
        Text('30 min', style: TextStyle(color: Colors.white70)),
        SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => _showTimePicker(context, 'Sunset'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple.withOpacity(0.2),
            foregroundColor: Colors.purple,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text('Edit'),
        ),
      ],
    );
  }
}

/// ✅ FIXED: Time picker dialog
void _showTimePicker(BuildContext context, String type) {
  showTimePicker(
    context: context,
    initialTime: TimeOfDay.now(),
  ).then((selectedTime) {
    if (selectedTime != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$type: ${selectedTime.format(context)}')),
      );
    }
  });
}