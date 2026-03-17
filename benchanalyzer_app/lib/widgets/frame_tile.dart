import 'package:flutter/material.dart';

import '../ble/ble_constants.dart';
import '../models/decoded_frame.dart';
import 'uart_waveform_widgets.dart';

class FrameTile extends StatelessWidget {
  const FrameTile({super.key, required this.frame});

  final DecodedFrame frame;

  @override
  Widget build(BuildContext context) {
    final protocolColor = frame.protocolKind.tint;
    final showWaveform = frame.protocolKind == ProtocolKind.uart;
    final waveform = UartWaveformCodec.fromFrame(frame);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: protocolColor.withValues(alpha: 0.35)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            offset: Offset(0, 3),
            color: Color(0x12000000),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: protocolColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  frame.protocolKind.label,
                  style: TextStyle(
                    color: protocolColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${frame.timestampUs} us',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (showWaveform) ...[
            UartWaveformPreview(series: waveform, color: protocolColor),
            const SizedBox(height: 10),
          ],
          SelectableText(
            frame.data,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
