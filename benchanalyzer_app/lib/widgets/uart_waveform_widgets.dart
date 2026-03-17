import 'package:flutter/material.dart';

import '../models/decoded_frame.dart';

class UartWaveformBytePoint {
  const UartWaveformBytePoint({
    required this.frameTimestampUs,
    required this.byteIndex,
    required this.byteValue,
  });

  final int frameTimestampUs;
  final int byteIndex;
  final int byteValue;
}

class UartWaveformSeries {
  const UartWaveformSeries({
    required this.levels,
    required this.points,
    required this.byteCount,
  });

  final List<bool> levels;
  final List<UartWaveformBytePoint> points;
  final int byteCount;

  bool get isEmpty => levels.isEmpty || points.isEmpty;

  static const UartWaveformSeries empty = UartWaveformSeries(
    levels: <bool>[],
    points: <UartWaveformBytePoint>[],
    byteCount: 0,
  );
}

class UartWaveformCodec {
  const UartWaveformCodec._();

  static UartWaveformSeries fromFrame(DecodedFrame frame, {int maxBytes = 10}) {
    final bytes = _extractUartPayloadBytes(frame.data, maxBytes: maxBytes);
    if (bytes.isEmpty) {
      return UartWaveformSeries.empty;
    }

    final levels = <bool>[true];
    final points = <UartWaveformBytePoint>[];

    for (var i = 0; i < bytes.length; i++) {
      final byte = bytes[i];
      points.add(
        UartWaveformBytePoint(
          frameTimestampUs: frame.timestampUs,
          byteIndex: i,
          byteValue: byte,
        ),
      );

      levels.add(false);
      for (var bitIndex = 0; bitIndex < 8; bitIndex++) {
        levels.add(((byte >> bitIndex) & 1) == 1);
      }
      levels.add(true);
      levels.add(true);
    }

    return UartWaveformSeries(
      levels: levels,
      points: points,
      byteCount: bytes.length,
    );
  }

  static UartWaveformSeries fromFrames(
    List<DecodedFrame> frames, {
    int maxFrames = 8,
    int maxBytesPerFrame = 8,
  }) {
    final uartFrames = frames
        .where((f) => f.protocol.toLowerCase() == 'uart')
        .take(maxFrames)
        .toList(growable: false)
        .reversed
        .toList(growable: false);

    if (uartFrames.isEmpty) {
      return UartWaveformSeries.empty;
    }

    final levels = <bool>[true];
    final points = <UartWaveformBytePoint>[];

    for (final frame in uartFrames) {
      final bytes = _extractUartPayloadBytes(
        frame.data,
        maxBytes: maxBytesPerFrame,
      );
      for (var i = 0; i < bytes.length; i++) {
        final byte = bytes[i];
        points.add(
          UartWaveformBytePoint(
            frameTimestampUs: frame.timestampUs,
            byteIndex: i,
            byteValue: byte,
          ),
        );

        levels.add(false);
        for (var bitIndex = 0; bitIndex < 8; bitIndex++) {
          levels.add(((byte >> bitIndex) & 1) == 1);
        }
        levels.add(true);
        levels.add(true);
      }
    }

    if (points.isEmpty) {
      return UartWaveformSeries.empty;
    }

    return UartWaveformSeries(
      levels: levels,
      points: points,
      byteCount: points.length,
    );
  }

  static List<int> _extractUartPayloadBytes(
    String raw, {
    required int maxBytes,
  }) {
    final text = raw.trim();
    if (text.isEmpty) {
      return const [];
    }

    final bytes = <int>[];

    final hexPrefixed = RegExp(r'0x([0-9a-fA-F]{1,2})').allMatches(text);
    for (final match in hexPrefixed) {
      final value = int.tryParse(match.group(1)!, radix: 16);
      if (value != null && value >= 0 && value <= 255) {
        bytes.add(value);
      }
    }

    if (bytes.isNotEmpty) {
      return bytes.take(maxBytes).toList(growable: false);
    }

    final tokens = text.split(RegExp(r'[^0-9A-Za-z]+'));
    for (final token in tokens) {
      if (token.isEmpty) {
        continue;
      }

      final value = _parseByteToken(token);
      if (value != null) {
        bytes.add(value);
      }
    }

    if (bytes.isNotEmpty) {
      return bytes.take(maxBytes).toList(growable: false);
    }

    return text.codeUnits.take(maxBytes).toList(growable: false);
  }

  static int? _parseByteToken(String token) {
    if (token.startsWith('0b') && token.length > 2) {
      return _byteOrNull(int.tryParse(token.substring(2), radix: 2));
    }

    if (RegExp(r'^[01]{8}$').hasMatch(token)) {
      return _byteOrNull(int.tryParse(token, radix: 2));
    }

    if (token.startsWith('0x') && token.length > 2) {
      return _byteOrNull(int.tryParse(token.substring(2), radix: 16));
    }

    if (RegExp(r'^[0-9a-fA-F]{1,2}$').hasMatch(token) &&
        RegExp(r'[a-fA-F]').hasMatch(token)) {
      return _byteOrNull(int.tryParse(token, radix: 16));
    }

    if (RegExp(r'^[0-9]{1,3}$').hasMatch(token)) {
      return _byteOrNull(int.tryParse(token));
    }

    return null;
  }

  static int? _byteOrNull(int? value) {
    if (value == null || value < 0 || value > 255) {
      return null;
    }
    return value;
  }
}

class UartWaveformPreview extends StatelessWidget {
  const UartWaveformPreview({
    super.key,
    required this.series,
    required this.color,
    this.height = 56,
  });

  final UartWaveformSeries series;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'UART waveform (${series.byteCount} byte${series.byteCount == 1 ? '' : 's'})',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: height,
            width: double.infinity,
            child: CustomPaint(
              painter: _UartWaveformPainter(
                levels: series.levels,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UartWaveformPanel extends StatefulWidget {
  const UartWaveformPanel({
    super.key,
    required this.frames,
    this.color = const Color(0xFF0A66C2),
  });

  final List<DecodedFrame> frames;
  final Color color;

  @override
  State<UartWaveformPanel> createState() => _UartWaveformPanelState();
}

class _UartWaveformPanelState extends State<UartWaveformPanel> {
  int? _selectedByte;

  @override
  Widget build(BuildContext context) {
    final series = UartWaveformCodec.fromFrames(widget.frames);
    if (series.isEmpty) {
      return const Center(
        child: Text(
          'No UART frames available yet. Start capture and select UART.',
        ),
      );
    }

    final selected =
        _selectedByte == null || _selectedByte! >= series.points.length
        ? null
        : series.points[_selectedByte!];

    final totalSteps = series.levels.length - 1;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rolling UART waveform',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Newest on right. Tap waveform to inspect a byte.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.color.withValues(alpha: 0.25)),
              ),
              padding: const EdgeInsets.all(10),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (details) {
                      if (series.points.isEmpty ||
                          constraints.maxWidth <= 0 ||
                          totalSteps <= 0) {
                        return;
                      }

                      final rawStep =
                          (details.localPosition.dx / constraints.maxWidth) *
                          totalSteps;
                      final byteIndex = (rawStep / 11).floor().clamp(
                        0,
                        series.points.length - 1,
                      );
                      setState(() {
                        _selectedByte = byteIndex;
                      });
                    },
                    child: CustomPaint(
                      painter: _UartWaveformPainter(
                        levels: series.levels,
                        color: widget.color,
                        selectedByteIndex: _selectedByte,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            selected == null
                ? 'Tap to inspect: byte value, character, and source frame timestamp.'
                : 'Selected: 0x${selected.byteValue.toRadixString(16).padLeft(2, '0').toUpperCase()} '
                      '(${selected.byteValue}) '
                      '${_printableChar(selected.byteValue)} '
                      'from frame ${selected.frameTimestampUs} us, byte #${selected.byteIndex}.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _printableChar(int value) {
    if (value >= 32 && value <= 126) {
      return "'${String.fromCharCode(value)}'";
    }
    return '(non-printable)';
  }
}

class _UartWaveformPainter extends CustomPainter {
  const _UartWaveformPainter({
    required this.levels,
    required this.color,
    this.selectedByteIndex,
  });

  final List<bool> levels;
  final Color color;
  final int? selectedByteIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (levels.length < 2 || size.width <= 0 || size.height <= 0) {
      return;
    }

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final axisPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..strokeWidth = 1;

    final markerPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final highY = 10.0;
    final lowY = size.height - 10.0;
    final stepWidth = size.width / (levels.length - 1);

    if (selectedByteIndex != null && selectedByteIndex! >= 0) {
      final startStep = (selectedByteIndex! * 11).toDouble();
      final endStep = ((selectedByteIndex! + 1) * 11).toDouble();
      final startX = startStep * stepWidth;
      final endX = endStep * stepWidth;
      canvas.drawRect(Rect.fromLTRB(startX, 0, endX, size.height), markerPaint);
    }

    canvas.drawLine(Offset(0, highY), Offset(size.width, highY), axisPaint);
    canvas.drawLine(Offset(0, lowY), Offset(size.width, lowY), axisPaint);

    final path = Path();
    var currentY = levels.first ? highY : lowY;
    path.moveTo(0, currentY);

    for (var i = 1; i < levels.length; i++) {
      final x = i * stepWidth;
      final nextY = levels[i] ? highY : lowY;

      path.lineTo(x, currentY);
      if (nextY != currentY) {
        path.lineTo(x, nextY);
      }
      currentY = nextY;
    }

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _UartWaveformPainter oldDelegate) {
    if (oldDelegate.color != color ||
        oldDelegate.selectedByteIndex != selectedByteIndex ||
        oldDelegate.levels.length != levels.length) {
      return true;
    }

    for (var i = 0; i < levels.length; i++) {
      if (oldDelegate.levels[i] != levels[i]) {
        return true;
      }
    }

    return false;
  }
}
