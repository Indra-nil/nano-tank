import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'ble_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final bleManager = Provider.of<BleManager>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aquarium LED Control'),
        actions: [
          IconButton(
            tooltip: 'Scan devices',
            icon: Icon(
              bleManager.isScanning
                  ? Icons.sync
                  : Icons.search,
            ),
            onPressed: () async {
              await bleManager.startScan();
              if (mounted) {
                _showDevicePicker(context, bleManager);
              }
            },
          ),
          IconButton(
            tooltip: 'Reconnect last',
            icon: Icon(
              bleManager.isConnected
                  ? Icons.bluetooth_connected
                  : Icons.bluetooth,
            ),
            onPressed: bleManager.reconnect,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (index) => setState(() => _selectedTab = index),
        selectedItemColor:
            const Color.fromARGB(255, 33, 243, 180),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb),
            label: 'Light',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timer),
            label: 'Timers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.co2),
            label: 'CO₂',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Time Sync',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedTab) {
      case 0:
        return const ControlTab();
      case 1:
        return const TimersTab();
      case 2:
        return const CO2Tab();
      case 3:
        return const TimeSyncTab();
      default:
        return const ControlTab();
    }
  }

  void _showDevicePicker(BuildContext context, BleManager bleManager) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final results = bleManager.scanResults;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                leading: Icon(Icons.bluetooth_searching),
                title: Text('Select AquariumLED device'),
              ),
              if (results.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No AquariumLED devices found.\n'
                    'Make sure ESP32 is powered and advertising.',
                    textAlign: TextAlign.center,
                  ),
                ),
              if (results.isNotEmpty)
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final r = results[index];
                      final name = r.device.platformName.isNotEmpty
                          ? r.device.platformName
                          : r.device.remoteId.str;
                      return ListTile(
                        leading: const Icon(Icons.memory),
                        title: Text(name),
                        subtitle: Text(
                          'RSSI: ${r.rssi}  •  ${r.device.remoteId.str}',
                        ),
                        onTap: () async {
                          Navigator.of(context).pop();
                          await bleManager.connectToDevice(r);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class ControlTab extends StatelessWidget {
  const ControlTab({super.key});

  @override
  Widget build(BuildContext context) {
    final bleManager = Provider.of<BleManager>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStatusCard(context, bleManager),
          const SizedBox(height: 20),
          _buildCurrentStatus(bleManager),
          const SizedBox(height: 20),
          _buildQuickModes(bleManager),
          const SizedBox(height: 20),
          _buildManualBrightnessControl(bleManager),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, BleManager bleManager) {
    return Card(
      color: bleManager.isConnected
          ? Colors.green.shade100
          : Colors.red.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  bleManager.isConnected
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth_disabled,
                  color:
                      bleManager.isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bleManager.status,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: bleManager.isConnected
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      if (bleManager.connectedDevice != null)
                        Text(
                          bleManager.connectedDevice!.platformName,
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                ),
                if (bleManager.isScanning)
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child:
                        CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    await bleManager.startScan();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Scan complete'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('SCAN'),
                ),
                const SizedBox(width: 10),
                if (bleManager.connectedDevice != null)
                  OutlinedButton.icon(
                    onPressed: () => _showRenameDialog(
                      context,
                      bleManager,
                    ),
                    icon: const Icon(Icons.edit),
                    label: const Text('RENAME'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(
      BuildContext context, BleManager bleManager) {
    final controller = TextEditingController(
      text: bleManager.connectedDevice?.platformName ?? '',
    );
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Rename device'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'New name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  await bleManager.renameDevice(name);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Rename command sent: $name'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                }
                Navigator.of(ctx).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCurrentStatus(BleManager bleManager) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text("Mode:",
                    style: TextStyle(fontSize: 16)),
                Chip(
                  label: Text(
                    bleManager.mode,
                    style:
                        const TextStyle(color: Colors.white),
                  ),
                  backgroundColor:
                      _getModeColor(bleManager.mode),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text("Brightness:",
                    style: TextStyle(fontSize: 16)),
                Text(
                  "${bleManager.brightness}%",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text("Max Brightness:",
                    style: TextStyle(fontSize: 16)),
                Text(
                  "${bleManager.maxBrightness}%",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getModeColor(String mode) {
    switch (mode) {
      case "AUTO":
        return Colors.blue;
      case "MANUAL":
        return Colors.orange;
      case "ON":
        return Colors.green;
      case "OFF":
        return Colors.red;
      case "DAY":
        return Colors.amber;
      case "NIGHT":
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  Widget _buildQuickModes(BleManager bleManager) {
    const List<Map<String, dynamic>> modes = [
      {
        "name": "ON",
        "command": "ON",
        "color": Colors.green,
        "icon": Icons.power
      },
      {
        "name": "OFF",
        "command": "OFF",
        "color": Colors.red,
        "icon": Icons.power_off
      },
      {
        "name": "DAY",
        "command": "DAY",
        "color": Colors.amber,
        "icon": Icons.wb_sunny
      },
      {
        "name": "NIGHT",
        "command": "NIGHT",
        "color": Colors.indigo,
        "icon": Icons.nightlight
      },
      {
        "name": "AUTO",
        "command": "AUTO",
        "color": Colors.blue,
        "icon": Icons.auto_awesome
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Quick Modes",
          style:
              TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          "AUTO: Follows sunrise/sunset schedule\n"
          "ON/DAY: Full brightness\n"
          "OFF/NIGHT: Lights off",
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 10),
        Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: _buildModeButton(modes[0], bleManager)),
                const SizedBox(width: 10),
                Expanded(
                    child: _buildModeButton(modes[1], bleManager)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: _buildModeButton(modes[2], bleManager)),
                const SizedBox(width: 10),
                Expanded(
                    child: _buildModeButton(modes[3], bleManager)),
              ],
            ),
            const SizedBox(height: 10),
            _buildAutoButton(modes[4], bleManager),
          ],
        ),
      ],
    );
  }

  Widget _buildModeButton(
      Map<String, dynamic> mode, BleManager bleManager) {
    final isActive = bleManager.mode == mode["name"];
    return ElevatedButton(
      onPressed: () => bleManager.setMode(mode["command"]),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive
            ? mode["color"]
            : mode["color"].withOpacity(0.6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(mode["icon"], color: Colors.white),
          const SizedBox(width: 8),
          Text(
            mode["name"],
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoButton(
      Map<String, dynamic> mode, BleManager bleManager) {
    final isActive = bleManager.mode == mode["name"];
    return ElevatedButton(
      onPressed: () => bleManager.setMode(mode["command"]),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive
            ? mode["color"]
            : mode["color"].withOpacity(0.6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        minimumSize: const Size(double.infinity, 0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(mode["icon"], color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Text(
            "${mode["name"]} MODE",
            style: const TextStyle(
                color: Colors.white, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildManualBrightnessControl(
      BleManager bleManager) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Manual Brightness Control",
          style:
              TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          "Adjust brightness in manual modes",
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Brightness:",
                        style: TextStyle(fontSize: 16)),
                    Text(
                      "${bleManager.brightness}%",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Slider(
                  value: bleManager.brightness.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 100,
                  label: "${bleManager.brightness}%",
                  onChanged: (value) {
                    bleManager.setBrightness(value.round());
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


class TimersTab extends StatefulWidget {
  const TimersTab({super.key});

  @override
  State<TimersTab> createState() => _TimersTabState();
}

class _TimersTabState extends State<TimersTab> {
  TimeOfDay _selectedSunriseTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _selectedSunsetTime = const TimeOfDay(hour: 20, minute: 0);
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (!_initialized) {
      final bleManager = Provider.of<BleManager>(context, listen: false);
      _selectedSunriseTime = TimeOfDay(
        hour: bleManager.photoStart ~/ 60,
        minute: bleManager.photoStart % 60,
      );
      _selectedSunsetTime = TimeOfDay(
        hour: bleManager.photoEnd ~/ 60,
        minute: bleManager.photoEnd % 60,
      );
      _initialized = true;
    }
  }

  Future<void> _selectSunriseTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedSunriseTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.orange,
              onPrimary: Colors.white,
            ),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteTextColor: Colors.black,
              hourMinuteColor: Colors.orange.shade50,
              dayPeriodTextColor: Colors.black,
              dayPeriodColor: Colors.orange.shade50,
              dialHandColor: Colors.orange,
              dialBackgroundColor: Colors.orange.shade50,
              dayPeriodTextStyle: const TextStyle(fontSize: 16),
              hourMinuteTextStyle: const TextStyle(fontSize: 24),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedSunriseTime) {
      setState(() {
        _selectedSunriseTime = picked;
      });
      final bleManager = Provider.of<BleManager>(context, listen: false);
      int minutes = picked.hour * 60 + picked.minute;
      bleManager.setPhotoperiodStart(minutes);
    }
  }

  Future<void> _selectSunsetTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedSunsetTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.indigo,
              onPrimary: Colors.white,
            ),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteTextColor: Colors.black,
              hourMinuteColor: Colors.indigo.shade50,
              dayPeriodTextColor: Colors.black,
              dayPeriodColor: Colors.indigo.shade50,
              dialHandColor: Colors.indigo,
              dialBackgroundColor: Colors.indigo.shade50,
              dayPeriodTextStyle: const TextStyle(fontSize: 16),
              hourMinuteTextStyle: const TextStyle(fontSize: 24),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedSunsetTime) {
      setState(() {
        _selectedSunsetTime = picked;
      });
      final bleManager = Provider.of<BleManager>(context, listen: false);
      int minutes = picked.hour * 60 + picked.minute;
      bleManager.setPhotoperiodEnd(minutes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bleManager = Provider.of<BleManager>(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Maximum Brightness Control (Added here)
          _buildMaxBrightnessControl(bleManager),
          const SizedBox(height: 20),
          
          const Text(
            "Sunrise/Sunset Duration",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          // Duration Controls
          Row(
            children: [
              Expanded(
                child: _buildDurationCard(
                  "Sunrise",
                  "Fade-in Duration",
                  bleManager.sunriseDuration,
                  Icons.sunny,
                  Colors.orange,
                  (value) => bleManager.setSunriseDuration(value),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDurationCard(
                  "Sunset",
                  "Fade-out Duration",
                  bleManager.sunsetDuration,
                  Icons.nightlight_round,
                  Colors.indigo,
                  (value) => bleManager.setSunsetDuration(value),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 30),
          
          const Text(
            "Photoperiod Schedule",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            "Set sunrise (lights on) and sunset (lights off) times",
            style: TextStyle(color: Colors.grey),
          ),
          
          const SizedBox(height: 20),
          
          // Sunrise Time Picker
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.sunny, color: Colors.orange.shade700, size: 28),
                      const SizedBox(width: 10),
                      const Text(
                        "Sunrise Time",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "When lights should start turning on",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  
                  // Time Display Button
                  InkWell(
                    onTap: () => _selectSunriseTime(context),
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 25),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.orange.shade200, width: 2),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.access_time, color: Colors.orange, size: 40),
                          const SizedBox(height: 10),
                          Text(
                            "TAP TO SET TIME",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _selectedSunriseTime.format(context),
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "(${_selectedSunriseTime.hour.toString().padLeft(2, '0')}:${_selectedSunriseTime.minute.toString().padLeft(2, '0')})",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Sunset Time Picker
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.nightlight_round, color: Colors.indigo.shade700, size: 28),
                      const SizedBox(width: 10),
                      const Text(
                        "Sunset Time",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "When lights should start turning off",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  
                  // Time Display Button
                  InkWell(
                    onTap: () => _selectSunsetTime(context),
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 25),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.indigo.shade200, width: 2),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.access_time, color: Colors.indigo, size: 40),
                          const SizedBox(height: 10),
                          Text(
                            "TAP TO SET TIME",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.indigo.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _selectedSunsetTime.format(context),
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "(${_selectedSunsetTime.hour.toString().padLeft(2, '0')}:${_selectedSunsetTime.minute.toString().padLeft(2, '0')})",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.indigo.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20)
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Schedule Summary
          Card(
            //color: const Color.fromARGB(153, 227, 242, 253),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.blue.shade700, size: 28),
                      const SizedBox(width: 10),
                      const Text(
                        "Schedule Summary",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Timeline Visualization
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      //color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      children: [
                        // Timeline
                        Stack(
                          children: [
                            // Background line
                            Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            // Light period
                            Positioned(
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.orange.shade300,
                                      Colors.indigo.shade300,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            // Sunrise marker
                            Positioned(
                              left: 0,
                              child: Column(
                                children: [
                                  Icon(Icons.sunny, color: Colors.orange, size: 24),
                                  const SizedBox(height: 5),
                                  Text(
                                    _selectedSunriseTime.format(context),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Sunset marker
                            Positioned(
                              right: 0,
                              child: Column(
                                children: [
                                  Icon(Icons.nightlight_round, color: Colors.indigo, size: 24),
                                  const SizedBox(height: 5),
                                  Text(
                                    _selectedSunsetTime.format(context),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // Details
                        Row(
                          children: [
                            Expanded(
                              child: _buildTimeDetail(
                                Icons.sunny,
                                "Sunrise Start",
                                _selectedSunriseTime.format(context),
                                "${bleManager.sunriseDuration} min pick",
                                Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildTimeDetail(
                                Icons.nightlight_round,
                                "Sunset Start",
                                _selectedSunsetTime.format(context),
                                "${bleManager.sunsetDuration} min fade",
                                Colors.indigo,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Total Duration
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.timer, color: Colors.blue.shade700, size: 32),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Total Light Period",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                    Text(
                                      _calculatePhotoperiod(_selectedSunriseTime, _selectedSunsetTime),
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Save/Restore Buttons
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    "Settings Management",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            bleManager.saveAllSettings();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('All settings saved to DEVICE memory'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          icon: const Icon(Icons.save, size: 20),
                          label: const Text("SAVE TO DEVICE"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Factory Reset"),
                                content: const Text(
                                  "Reset all settings to defaults? This cannot be undone.",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("CANCEL"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      bleManager.sendCommand("FACTORY_RESET");
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Factory reset complete'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    },
                                    child: const Text("RESET", style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.restart_alt, size: 20),
                          label: const Text("FACTORY RESET"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade200,
                            foregroundColor: Colors.grey.shade800,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Settings are automatically saved when changed. "
                    "Use 'SAVE TO DEVICE' to force save current state.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Add this method to TimersTab
  Widget _buildMaxBrightnessControl(BleManager bleManager) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Maximum Daytime Brightness",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          "Peak brightness during daytime in AUTO mode",
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Max Brightness:", style: TextStyle(fontSize: 16)),
                    Text(
                      "${bleManager.maxBrightness}%",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Slider(
                  value: bleManager.maxBrightness.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 100,
                  label: "${bleManager.maxBrightness}%",
                  onChanged: (value) {
                    bleManager.setMaxBrightness(value.round());
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildDurationCard(
    String title,
    String subtitle,
    int duration,
    IconData icon,
    Color color,
    Function(int) onChanged,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 15),
            
            // Duration Display
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  "$duration min",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 15),
            
            // Duration Slider
            Slider(
              value: duration.toDouble(),
              min: 0,
              max: 60,
              divisions: 60,
              label: "$duration min",
              activeColor: color,
              inactiveColor: color.withOpacity(0.3),
              onChanged: (value) => onChanged(value.round()),
            ),
          ],
        ),
      ),
    );
  }
    
  Widget _buildTimeDetail(IconData icon, String title, String time, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
  
  String _calculatePhotoperiod(TimeOfDay sunrise, TimeOfDay sunset) {
    int sunriseMinutes = sunrise.hour * 60 + sunrise.minute;
    int sunsetMinutes = sunset.hour * 60 + sunset.minute;
    
    int duration = sunsetMinutes - sunriseMinutes;
    if (duration < 0) duration += 1440;
    
    int hours = duration ~/ 60;
    int minutes = duration % 60;
    
    if (minutes == 0) {
      return "$hours hours";
    } else {
      return "$hours hr $minutes min";
    }
  }
}

class CO2Tab extends StatefulWidget {
  const CO2Tab({super.key});

  @override
  State<CO2Tab> createState() => _CO2TabState();
}

class _CO2TabState extends State<CO2Tab> {
  TimeOfDay _selectedCO2StartTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _selectedCO2EndTime = const TimeOfDay(hour: 17, minute: 0);
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (!_initialized) {
      final bleManager = Provider.of<BleManager>(context, listen: false);
      _selectedCO2StartTime = TimeOfDay(
        hour: bleManager.co2Start ~/ 60,
        minute: bleManager.co2Start % 60,
      );
      _selectedCO2EndTime = TimeOfDay(
        hour: bleManager.co2End ~/ 60,
        minute: bleManager.co2End % 60,
      );
      _initialized = true;
    }
  }

  Future<void> _selectCO2StartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedCO2StartTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.green,
              onPrimary: Colors.white,
            ),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedCO2StartTime) {
      setState(() {
        _selectedCO2StartTime = picked;
      });
      final bleManager = Provider.of<BleManager>(context, listen: false);
      int minutes = picked.hour * 60 + picked.minute;
      bleManager.setCO2Start(minutes);
    }
  }

  Future<void> _selectCO2EndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedCO2EndTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.green,
              onPrimary: Colors.white,
            ),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedCO2EndTime) {
      setState(() {
        _selectedCO2EndTime = picked;
      });
      final bleManager = Provider.of<BleManager>(context, listen: false);
      int minutes = picked.hour * 60 + picked.minute;
      bleManager.setCO2End(minutes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bleManager = Provider.of<BleManager>(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CO2 Status Card
          Card(
            color: bleManager.co2Enabled ? Colors.green.shade100 : Colors.red.shade100,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.co2,
                    color: bleManager.co2Enabled ? Colors.green : Colors.red,
                    size: 32,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bleManager.co2Enabled ? "CO₂: ON" : "CO₂: OFF",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: bleManager.co2Enabled ? Colors.green : Colors.red,
                          ),
                        ),
                        Text(
                          "${_selectedCO2StartTime.format(context)} - ${_selectedCO2EndTime.format(context)}",
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: bleManager.co2Enabled,
                    onChanged: (value) {
                      bleManager.setCO2Enabled(value);
                    },
                    activeColor: Colors.green,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // CO2 Start Time
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "CO₂ Start Time",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "When CO₂ solenoid should turn on",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  
                  InkWell(
                    onTap: () => _selectCO2StartTime(context),
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.green.shade200, width: 2),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.play_arrow, color: Colors.green, size: 40),
                          const SizedBox(height: 10),
                          Text(
                            "START TIME",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _selectedCO2StartTime.format(context),
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // CO2 End Time
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "CO₂ End Time",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "When CO₂ solenoid should turn off",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  
                  InkWell(
                    onTap: () => _selectCO2EndTime(context),
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.red.shade200, width: 2),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.stop, color: Colors.red, size: 40),
                          const SizedBox(height: 10),
                          Text(
                            "END TIME",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _selectedCO2EndTime.format(context),
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // CO2 Schedule Info
          Card(
            //color: Colors.blueGrey.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blueGrey.shade700),
                      const SizedBox(width: 10),
                      const Text(
                        "CO₂ Schedule Info",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "• CO₂ is typically run during daylight hours when plants are photosynthesizing\n"
                    "• Recommended: Start 1 hour after lights on, end 1 hour before lights off\n"
                    "• Adjust based on plant requirements and fish behavior\n"
                    "• Monitor pH levels when adjusting CO₂ schedule",
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TimeSyncTab extends StatelessWidget {
  const TimeSyncTab({super.key});

  @override
  Widget build(BuildContext context) {
    final bleManager = Provider.of<BleManager>(context);
    
    return SingleChildScrollView(
      child: Column(
        children: [
          Card(
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
                        "RTC Time",
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
                        onPressed: bleManager.isConnected
                            ? () async {
                                await bleManager.syncTimeFromPhone();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Time synchronized successfully!'),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            : null,
                        icon: const Icon(Icons.sync, size: 24),
                        label: const Text(
                          "SYNC TIME FROM PHONE",
                          style: TextStyle(fontSize: 16),
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
                    "RTC maintains accurate time during power outages. "
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
          ),
          
          // Time Synchronization Info Card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Time Synchronization Info",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "• The RTC (Real-Time Clock) keeps accurate time "
                    "even when the DEVICE is powered off.\n\n"
                    "• Sync your phone's time to the RTC for precise "
                    "sunrise/sunset scheduling.\n\n"
                    "• Time is displayed live and updates every second.\n\n"
                    "• Schedule accuracy is maintained during power outages.",
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 15),
                  ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: const Text("Automatic Schedule"),
                    subtitle: const Text("Sunrise/sunset run automatically based on RTC time"),
                  ),
                  ListTile(
                    leading: const Icon(Icons.battery_charging_full, color: Colors.green),
                    title: const Text("Battery Backup"),
                    subtitle: const Text("has built-in battery for power outage protection"),
                  ),
                  ListTile(
                    leading: const Icon(Icons.precision_manufacturing, color: Colors.green),
                    title: const Text("High Accuracy"),
                    subtitle: const Text("±2ppm accuracy (about 1 minute per year)"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}