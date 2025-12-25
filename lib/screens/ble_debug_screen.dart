// import 'package:flutter/material.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'package:permission_handler/permission_handler.dart';

// class BleDebugScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('🔧 BLE DEBUG'), backgroundColor: Colors.orange),
//       body: Padding(
//         padding: EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('BLE STATUS:', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
//             SizedBox(height: 20),
            
//             // 1. Bluetooth Adapter
//             FutureBuilder(
//               future: FlutterBluePlus.adapterState.first,
//               builder: (context, snapshot) {
//                 final enabled = snapshot.data == BluetoothAdapterState.on;
//                 return _StatusTile('Bluetooth Adapter', enabled, Icons.bluetooth);
//               },
//             ),
            
//             // 2. Location Permission
//             FutureBuilder(
//               future: Permission.location.status,
//               builder: (context, snapshot) {
//                 final granted = snapshot.data?.isGranted ?? false;
//                 return _StatusTile('Location Permission', granted, Icons.location_on);
//               },
//             ),
            
//             // 3. Bluetooth Permission
//             FutureBuilder(
//               future: Permission.bluetooth.status,
//               builder: (context, snapshot) {
//                 final granted = snapshot.data?.isGranted ?? false;
//                 return _StatusTile('Bluetooth Permission', granted, Icons.security);
//               },
//             ),
            
//             // 4. Bluetooth Scan Permission
//             FutureBuilder(
//               future: Permission.bluetoothScan.status,
//               builder: (context, snapshot) {
//                 final granted = snapshot.data?.isGranted ?? false;
//                 return _StatusTile('Bluetooth Scan', granted, Icons.wifi_find);
//               },
//             ),
            
//             SizedBox(height: 30),
//             Center(
//               child: Column(
//                 children: [
//                   ElevatedButton.icon(
//                     onPressed: () => _requestPermissions(context),
//                     icon: Icon(Icons.security),
//                     label: Text('🔧 REQUEST PERMISSIONS'),
//                     style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
//                   ),
//                   SizedBox(height: 10),
//                   ElevatedButton.icon(
//                     onPressed: () => Navigator.pop(context),
//                     icon: Icon(Icons.arrow_back),
//                     label: Text('BACK'),
//                     style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _requestPermissions(BuildContext context) async {
//     await [
//       Permission.location,
//       Permission.bluetooth,
//       Permission.bluetoothScan,
//       Permission.bluetoothConnect,
//     ].request();

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('✅ Permissions updated! Go SCAN'), backgroundColor: Colors.green),
//     );
//   }
// }

// class _StatusTile extends StatelessWidget {
//   final String title;
//   final dynamic value;
//   final IconData icon;

//   const _StatusTile(this.title, this.value, this.icon);

//   @override
//   Widget build(BuildContext context) {
//     final isGood = value == true;
//     return Card(
//       margin: EdgeInsets.only(bottom: 12),
//       color: isGood ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
//       child: ListTile(
//         leading: Icon(icon, color: isGood ? Colors.green : Colors.red),
//         title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
//         trailing: Container(
//           padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           decoration: BoxDecoration(
//             color: isGood ? Colors.green : Colors.red,
//             borderRadius: BorderRadius.circular(20),
//           ),
//           child: Text(
//             value.toString(),
//             style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//           ),
//         ),
//       ),
//     );
//   }
// }
