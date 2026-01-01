import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tank_provider.dart';
import '../widgets/glass_card.dart';
import 'tank_dashboard.dart';
import 'ble_scan_screen.dart';
//import 'ble_debug_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Nano Tanks',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [

          //  IconButton(
          //   icon: Icon(Icons.bug_report, color: Colors.orange),
          //   onPressed: () => Navigator.push(
          //     context, 
          //     MaterialPageRoute(builder: (_) => BleDebugScreen())
          //   ),
          // ),

          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white70),
            onPressed: () => Navigator.push(  // ✅ FIXED 1: BLE Scan Screen
              context, 
              MaterialPageRoute(builder: (_) => BleScanScreen())
            ),
          ),
        ],
      ),
      body: Consumer<TankProvider>(
        builder: (context, tankProvider, child) {
          // EMPTY STATE - First time user
          if (tankProvider.tanks.isEmpty) {
            return _EmptyState(
              onAddTank: () => Navigator.push(  // ✅ FIXED 2: BLE Scan Screen
                context, 
                MaterialPageRoute(builder: (_) => BleScanScreen())
              ),
            );
          }
          
          // TANKS LIST - User has tanks
          return ListView.builder(
            padding: EdgeInsets.all(20),
            itemCount: tankProvider.tanks.length + 1,
            itemBuilder: (context, index) {
              // + ADD TANK button at bottom
              if (index == tankProvider.tanks.length) {
                return GlassCard(
                  child: ListTile(
                    leading: Icon(Icons.add, color: Colors.cyan, size: 32),
                    title: Text(
                      'Add New Tank',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Scan for nearby controllers'),
                    trailing: Icon(Icons.arrow_forward_ios, color: Colors.cyan),
                    onTap: () => Navigator.push(  // ✅ FIXED 3: BLE Scan Screen
                      context, 
                      MaterialPageRoute(builder: (_) => BleScanScreen())
                    ),
                  ),
                );
              }
              
              // TANK CARD
              final tank = tankProvider.tanks[index];
              return GlassCard(
                child: ListTile(
                  contentPadding: EdgeInsets.all(20),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: tank.connected
                        ? Colors.green.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3),
                    child: Icon(
                      tank.connected ? Icons.wifi : Icons.wifi_off,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    tank.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'pH: ${tank.liveData.ph?.toStringAsFixed(1) ?? '-'}',
                        style: TextStyle(color: Colors.cyan),
                      ),
                      Text(
                        '${tank.tankConfig.pumps.where((p) => p.enabled).length}/4 pumps',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  trailing: tank.connected
                      ? Icon(Icons.arrow_forward_ios, color: Colors.cyan, size: 20)
                      : Icon(Icons.refresh, color: Colors.white70, size: 20),
                  onTap: tank.connected
                      ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TankDashboard(tank: tank),
                          ),
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddTank;
  
  const _EmptyState({required this.onAddTank});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Fish icon
            Icon(
              Icons.water_drop,
              size: 120,
              color: Colors.white.withOpacity(0.3),
            ),
            SizedBox(height: 32),
            
            // Title
            Text(
              'No tanks found',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            
            // Subtitle
            Text(
              'Connect your first tank controller\nand start automating your aquarium',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
            SizedBox(height: 48),
            
            // Big ADD TANK button
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: onAddTank,  // ✅ FIXED 4: Uses parent Navigator.push
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'ADD TANK',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Learn more link
            TextButton(
              onPressed: () {
                // Open setup guide
              },
              child: Text(
                'How to setup →',
                style: TextStyle(color: Colors.cyan),
              ),
            ),
          ],
        ),
      ),
    );
  }
}