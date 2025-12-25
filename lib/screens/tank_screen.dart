import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tank.dart';
import '../providers/tank_provider.dart';

class TankScreen extends StatelessWidget {
  final Tank tank;
  
  const TankScreen({Key? key, required this.tank}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tank.name),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(tank.connected ? Icons.bluetooth_connected : Icons.bluetooth_disabled),
            onPressed: () => context.read<TankProvider>().refreshTank(tank),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LIVE DATA CARD
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📊 Live Data', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: Text('pH: ${tank.liveData.ph?.toStringAsFixed(1) ?? '--'}')),
                        Expanded(child: Text('TDS: ${tank.liveData.tds?.toStringAsFixed(0) ?? '--'}')),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(child: Text('Temp: ${tank.liveData.temp?.toStringAsFixed(1) ?? '--'}°C')),
                        Expanded(child: Text('State: ${tank.liveData.state}')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // PUMP CONTROLS
            Text('💉 Pump Controls', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            
            ...tank.tankConfig.pumps.map((pump) => Card(
              margin: EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: pump.enabled ? Colors.green : Colors.grey,
                  child: Text('${pump.id + 1}'),
                ),
                title: Text(pump.name.isEmpty ? 'Pump ${pump.id + 1}' : pump.name),
                subtitle: Text('${pump.remainingMl.toStringAsFixed(0)}ml remaining'),
                trailing: Switch(
                  value: pump.enabled,
                  onChanged: (value) {
                    // TODO: Send to ESP32
                    print('Toggle pump ${pump.id}: $value');
                  },
                ),
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }
}
