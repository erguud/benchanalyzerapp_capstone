import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:app_settings/app_settings.dart';
import 'package:provider/provider.dart';

import '../state/analyzer_controller.dart';
import 'device_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyzerController>().startScan();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bench Analyzer'),
        actions: [
          Consumer<AnalyzerController>(
            builder: (context, controller, _) {
              if (controller.isScanning) {
                return IconButton(
                  tooltip: 'Stop scan',
                  onPressed: controller.stopScan,
                  icon: const Icon(Icons.stop_circle_outlined),
                );
              }
              return IconButton(
                tooltip: 'Scan',
                onPressed: controller.isBleReady ? controller.startScan : null,
                icon: const Icon(Icons.bluetooth_searching),
              );
            },
          ),
        ],
      ),
      body: Consumer<AnalyzerController>(
        builder: (context, controller, _) {
          final devices = controller.scanResults;
          final bleGuidance = controller.bleStatusGuidance;

          return Column(
            children: [
              _ScanStatusBanner(
                isScanning: controller.isScanning,
                count: devices.length,
                bleStatusName: controller.bleStatusName,
              ),
              if (bleGuidance != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: MaterialBanner(
                    leading: Icon(
                      controller.isMobileTarget
                          ? Icons.bluetooth_disabled
                          : Icons.phone_android,
                    ),
                    content: Text(bleGuidance),
                    actions: [
                      // Open Settings only makes sense on mobile platforms.
                      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
                        TextButton(
                          onPressed: AppSettings.openAppSettings,
                          child: const Text('Open Settings'),
                        ),
                      if (controller.isMobileTarget)
                        TextButton(
                          onPressed: controller.startScan,
                          child: const Text('Retry'),
                        ),
                    ],
                  ),
                ),
              if (controller.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: MaterialBanner(
                    content: Text(controller.errorMessage!),
                    actions: [
                      TextButton(
                        onPressed: controller.startScan,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: devices.isEmpty
                    ? const _EmptyScanState()
                    : ListView.separated(
                        itemCount: devices.length,
                        padding: const EdgeInsets.all(16),
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final device = devices[index];
                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.memory),
                              ),
                              title: Text(device.name),
                              subtitle: Text('RSSI: ${device.rssi} dBm'),
                              trailing: FilledButton.icon(
                                onPressed: () async {
                                  await controller.connectToDevice(device);
                                  if (!context.mounted) {
                                    return;
                                  }
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const DeviceScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.link),
                                label: const Text('Connect'),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ScanStatusBanner extends StatelessWidget {
  const _ScanStatusBanner({
    required this.isScanning,
    required this.count,
    required this.bleStatusName,
  });

  final bool isScanning;
  final int count;
  final String bleStatusName;

  @override
  Widget build(BuildContext context) {
    final color = isScanning ? const Color(0xFF0A66C2) : const Color(0xFF455A64);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            isScanning ? Icons.radar : Icons.bluetooth_disabled,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isScanning
                  ? 'Scanning for BenchAnalyzer devices...'
                  : 'Scan paused. BLE state: $bleStatusName.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            '$count found',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
    );
  }
}

class _EmptyScanState extends StatelessWidget {
  const _EmptyScanState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bluetooth_searching,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Searching for Bench Analyzer devices',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Make sure your ESP32 is powered and advertising as BenchAnalyzer-<id>.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
