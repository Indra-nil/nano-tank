import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ble_manager.dart';

class TimeSyncCard extends StatefulWidget {
  const TimeSyncCard({super.key});

  @override
  State<TimeSyncCard> createState() => _TimeSyncCardState();
}

class _TimeSyncCardState extends State<TimeSyncCard> {
  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    final bleManager = Provider.of<BleManager>(context);
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  "DS3231 RTC Time",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // ESP32 Time Display
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  // Time
                  Text(
                    bleManager.formattedEsp32Time,
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'RobotoMono',
                    ),
                  ),
                  
                  // Date
                  Text(
                    bleManager.formattedEsp32Date,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  
                  // Connection Status
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: bleManager.isConnected ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      bleManager.isConnected ? "LIVE" : "DISCONNECTED",
                      style: TextStyle(
                        color: bleManager.isConnected ? Colors.green.shade800 : Colors.red.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Phone Time
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.phone_android, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Phone Time",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          "${DateTime.now().hour.toString().padLeft(2, '0')}:"
                          "${DateTime.now().minute.toString().padLeft(2, '0')}:"
                          "${DateTime.now().second.toString().padLeft(2, '0')}",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Sync Button
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _isSyncing || !bleManager.isConnected
                      ? null
                      : () async {
                          setState(() => _isSyncing = true);
                          await bleManager.syncTimeFromPhone();
                          setState(() => _isSyncing = false);
                          
                          // Show success snackbar
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Time synchronized successfully!'),
                              backgroundColor: Colors.green.shade600,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                  icon: _isSyncing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Icon(Icons.sync, size: 24),
                  label: Text(
                    _isSyncing ? "SYNCING..." : "SYNC TIME FROM PHONE",
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 0),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Refresh Button
                OutlinedButton.icon(
                  onPressed: bleManager.isConnected
                      ? () {
                          bleManager.requestEsp32Time();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Time refreshed'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text("REFRESH TIME"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 0),
                  ),
                ),
              ],
            ),
            
            // Help Text
            const SizedBox(height: 16),
            const Text(
              "DS3231 RTC maintains accurate time during power outages. "
              "Sync ensures sunrise/sunset schedule runs precisely.",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}