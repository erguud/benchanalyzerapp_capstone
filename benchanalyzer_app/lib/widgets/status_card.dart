import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../ble/ble_constants.dart';
import '../models/analyzer_status.dart';

class StatusCard extends StatelessWidget {
  const StatusCard({
    super.key,
    required this.status,
    required this.connectionState,
    required this.liveFrameCount,
  });

  final AnalyzerStatus status;
  final DeviceConnectionState connectionState;
  final int liveFrameCount;

  @override
  Widget build(BuildContext context) {
    final protocol = ProtocolKindX.fromString(status.protocol);
    final connectionLabel = switch (connectionState) {
      DeviceConnectionState.connected => 'Connected',
      DeviceConnectionState.connecting => 'Connecting',
      DeviceConnectionState.disconnecting => 'Disconnecting',
      DeviceConnectionState.disconnected => 'Disconnected',
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              protocol.tint.withValues(alpha: 0.2),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.memory),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    status.deviceName.isEmpty ? 'Bench Analyzer' : status.deviceName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(
                  label: Text(connectionLabel),
                  avatar: Icon(
                    connectionState == DeviceConnectionState.connected
                        ? Icons.bluetooth_connected
                        : Icons.bluetooth,
                    size: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusPill(label: 'Protocol', value: protocol.label, color: protocol.tint),
                _StatusPill(
                  label: 'Capture',
                  value: status.capturing ? 'Active' : 'Inactive',
                  color: status.capturing
                      ? const Color(0xFF1E8E3E)
                      : const Color(0xFF6A737D),
                ),
                _StatusPill(
                  label: 'Live Frames',
                  value: '$liveFrameCount',
                  color: const Color(0xFF006B6B),
                ),
                _StatusPill(
                  label: 'Device Frames',
                  value: '${status.frames}',
                  color: const Color(0xFF4C6B9A),
                ),
                _StatusPill(
                  label: 'Errors',
                  value: '${status.errors}',
                  color: status.errors > 0
                      ? const Color(0xFFB3261E)
                      : const Color(0xFF6A737D),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.labelMedium,
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}
