import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tank_provider.dart';
import '../models/tank.dart';
import 'light_screen.dart';
import 'dosing_screen.dart';
import 'co2_screen.dart';
import 'data_screen.dart';

class TankDashboard extends StatelessWidget {
  final Tank tank;
  
  const TankDashboard({Key? key, required this.tank}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<TankProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: tank.connected 
                      ? Colors.green.withOpacity(0.4)
                      : Colors.orange.withOpacity(0.4),
                  child: Icon(tank.connected ? Icons.circle : Icons.circle_outlined),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tank.name, style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      'Status: ${tank.connected ? "Online" : "Offline"}',  // ✅ FIXED: Simple status
                      style: TextStyle(fontSize: 14, color: Colors.cyan),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.settings),
                onPressed: () => _showSettings(context),  // ✅ FIXED: Defined below
              ),
            ],
          ),
          body: _buildBody(context),  // ✅ FIXED: SwipeController replacement
          floatingActionButton: tank.connected 
              ? FloatingActionButton(
                  onPressed: () => provider.refreshTank(tank),  // ✅ Method exists
                  child: Icon(Icons.refresh),
                  backgroundColor: Colors.cyan,
                )
              : null,
        );
      },
    );
  }

  /// ✅ FIXED: SwipeController → TabBarView replacement
  Widget _buildBody(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          TabBar(
            labelColor: Colors.cyan,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.cyan,
            tabs: [
              Tab(text: 'LIGHT'),
              Tab(text: 'DOSING'),
              Tab(text: 'CO₂'),
              Tab(text: 'DATA'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                LightScreen(tank: tank),
                DosingScreen(tank: tank),
                Co2Screen(tank: tank),
                DataScreen(tank: tank),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ FIXED: Settings dialog
  void _showSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tank Settings'),
        content: Text('Settings for ${tank.name}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}