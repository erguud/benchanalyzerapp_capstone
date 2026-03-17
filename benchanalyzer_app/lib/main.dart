import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:provider/provider.dart';

import 'ble/ble_service.dart';
import 'screens/scan_screen.dart';
import 'state/analyzer_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final ble = FlutterReactiveBle();

  runApp(BenchAnalyzerApp(ble: ble));
}

class BenchAnalyzerApp extends StatelessWidget {
  const BenchAnalyzerApp({super.key, required this.ble});

  final FlutterReactiveBle ble;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AnalyzerController(BleService(ble)),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Bench Analyzer',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF005B8F),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF4F7FA),
          useMaterial3: true,
        ),
        home: const ScanScreen(),
      ),
    );
  }
}
