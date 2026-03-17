import 'package:flutter/material.dart';

class ControlPanel extends StatelessWidget {
  const ControlPanel({
    super.key,
    required this.isConnected,
    required this.onPing,
    required this.onRefreshStatus,
    required this.onSetUart,
    required this.onSetI2c,
    required this.onSetSpi,
    required this.onStartCapture,
    required this.onStopCapture,
    required this.onClearFrames,
  });

  final bool isConnected;
  final Future<void> Function() onPing;
  final Future<void> Function() onRefreshStatus;
  final Future<void> Function() onSetUart;
  final Future<void> Function() onSetI2c;
  final Future<void> Function() onSetSpi;
  final Future<void> Function() onStartCapture;
  final Future<void> Function() onStopCapture;
  final Future<void> Function() onClearFrames;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ControlButton(
              label: 'Ping',
              icon: Icons.wifi_tethering,
              enabled: isConnected,
              onPressed: onPing,
            ),
            _ControlButton(
              label: 'Refresh Status',
              icon: Icons.refresh,
              enabled: isConnected,
              onPressed: onRefreshStatus,
            ),
            _ControlButton(
              label: 'Set UART',
              icon: Icons.settings_ethernet,
              color: const Color(0xFF0A66C2),
              enabled: isConnected,
              onPressed: onSetUart,
            ),
            _ControlButton(
              label: 'Set I2C',
              icon: Icons.device_hub,
              color: const Color(0xFF2E8B57),
              enabled: isConnected,
              onPressed: onSetI2c,
            ),
            _ControlButton(
              label: 'Set SPI',
              icon: Icons.usb,
              color: const Color(0xFFDD7A12),
              enabled: isConnected,
              onPressed: onSetSpi,
            ),
            _ControlButton(
              label: 'Start Capture',
              icon: Icons.play_arrow,
              enabled: isConnected,
              onPressed: onStartCapture,
            ),
            _ControlButton(
              label: 'Stop Capture',
              icon: Icons.stop,
              enabled: isConnected,
              onPressed: onStopCapture,
            ),
            _ControlButton(
              label: 'Clear Frames',
              icon: Icons.cleaning_services,
              enabled: isConnected,
              onPressed: onClearFrames,
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.enabled,
    this.color,
  });

  final String label;
  final IconData icon;
  final Future<void> Function() onPressed;
  final bool enabled;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: enabled ? onPressed : null,
      style: color == null
          ? null
          : FilledButton.styleFrom(backgroundColor: color),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
