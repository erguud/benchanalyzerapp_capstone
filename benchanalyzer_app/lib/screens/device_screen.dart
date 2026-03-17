import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ble/ble_constants.dart';
import '../state/analyzer_controller.dart';
import '../widgets/control_panel.dart';
import '../widgets/frame_list.dart';
import '../widgets/protocol_filter_bar.dart';
import '../widgets/status_card.dart';

class DeviceScreen extends StatelessWidget {
  const DeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalyzerController>(
      builder: (context, controller, _) {
        final selected = controller.selectedDevice;

        return Scaffold(
          appBar: AppBar(
            title: Text(selected?.name ?? 'Analyzer'),
            actions: [
              IconButton(
                tooltip: 'Disconnect',
                onPressed: controller.disconnect,
                icon: const Icon(Icons.link_off),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: controller.refreshStatus,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (controller.errorMessage != null || !controller.isConnected)
                  _ConnectionBanner(controller: controller),
                if (controller.errorMessage != null || !controller.isConnected)
                  const SizedBox(height: 12),
                StatusCard(
                  status: controller.status,
                  connectionState: controller.connectionState,
                  liveFrameCount: controller.totalFramesReceived,
                ),
                const SizedBox(height: 12),
                ControlPanel(
                  isConnected: controller.isConnected,
                  onPing: controller.sendPing,
                  onRefreshStatus: controller.refreshStatus,
                  onSetUart: () => controller.setProtocol(ProtocolKind.uart),
                  onSetI2c: () => controller.setProtocol(ProtocolKind.i2c),
                  onSetSpi: () => controller.setProtocol(ProtocolKind.spi),
                  onStartCapture: controller.startCapture,
                  onStopCapture: controller.stopCapture,
                  onClearFrames: controller.clearFrames,
                ),
                const SizedBox(height: 12),
                ProtocolFilterBar(
                  activeFilter: controller.activeFilter,
                  onChanged: controller.setFilter,
                ),
                const SizedBox(height: 12),
                FrameList(
                  frames: controller.filteredFrames,
                  errorMessage: controller.errorMessage,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({required this.controller});

  final AnalyzerController controller;

  @override
  Widget build(BuildContext context) {
    final reconnectingText = controller.isReconnecting
        ? 'Auto reconnect attempt ${controller.reconnectAttempt} in progress...'
        : 'Disconnected from device.';

    final message = controller.errorMessage ?? reconnectingText;
    final bannerColor = controller.isConnected
        ? const Color(0xFFEAF6EA)
        : const Color(0xFFFFF4E5);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x33A15C00)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: controller.reconnect,
                icon: const Icon(Icons.refresh),
                label: const Text('Reconnect'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Auto reconnect'),
                  dense: true,
                  value: controller.autoReconnect,
                  onChanged: controller.setAutoReconnect,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
