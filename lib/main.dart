import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'providers/tank_provider.dart';
import 'providers/notifications_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('tanks');
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => TankProvider()),
      ChangeNotifierProvider(create: (_) => NotificationsProvider()),
    ],
    child: NanoTankApp(),
  ));
}

class NanoTankApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nano Tank Controller',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF4FC3F7),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Color(0xFF0A0E17),
      ),
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}