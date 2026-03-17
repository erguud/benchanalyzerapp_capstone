import 'package:flutter/material.dart';

import '../ble/ble_constants.dart';

class ProtocolFilterBar extends StatelessWidget {
  const ProtocolFilterBar({
    super.key,
    required this.activeFilter,
    required this.onChanged,
  });

  final ProtocolKind activeFilter;
  final ValueChanged<ProtocolKind> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          children: [
            for (final protocol in const [
              ProtocolKind.all,
              ProtocolKind.uart,
              ProtocolKind.i2c,
              ProtocolKind.spi,
            ])
              ChoiceChip(
                label: Text(protocol.label),
                selected: protocol == activeFilter,
                selectedColor: protocol.tint.withValues(alpha: 0.22),
                side: BorderSide(
                  color: protocol == activeFilter
                      ? protocol.tint
                      : Theme.of(context).dividerColor,
                ),
                onSelected: (_) => onChanged(protocol),
              ),
          ],
        ),
      ),
    );
  }
}
