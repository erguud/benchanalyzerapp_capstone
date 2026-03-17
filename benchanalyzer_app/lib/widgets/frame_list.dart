import 'package:flutter/material.dart';

import '../models/decoded_frame.dart';
import 'frame_tile.dart';
import 'uart_waveform_widgets.dart';

enum _ViewerMode { decoded, waveform }

class FrameList extends StatefulWidget {
  const FrameList({super.key, required this.frames, this.errorMessage});

  final List<DecodedFrame> frames;
  final String? errorMessage;

  @override
  State<FrameList> createState() => _FrameListState();
}

class _FrameListState extends State<FrameList> {
  _ViewerMode _mode = _ViewerMode.decoded;

  @override
  Widget build(BuildContext context) {
    final hasUartFrames = widget.frames.any(
      (f) => f.protocol.toLowerCase() == 'uart',
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 420,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.stream),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Live Frame Viewer',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              'Newest first. Showing ${widget.frames.length} frames.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton<_ViewerMode>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment<_ViewerMode>(
                          value: _ViewerMode.decoded,
                          icon: Icon(Icons.subject),
                          label: Text('Decoded'),
                        ),
                        ButtonSegment<_ViewerMode>(
                          value: _ViewerMode.waveform,
                          icon: Icon(Icons.show_chart),
                          label: Text('Waveform'),
                        ),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (selection) {
                        setState(() {
                          _mode = selection.first;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (widget.errorMessage != null)
              Container(
                width: double.infinity,
                color: const Color(0xFFFFF3E0),
                padding: const EdgeInsets.all(10),
                child: Text(
                  widget.errorMessage!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF8A4B00),
                  ),
                ),
              ),
            const Divider(height: 1),
            Expanded(
              child: widget.frames.isEmpty
                  ? const Center(
                      child: Text(
                        'No frames yet. Start capture to stream data.',
                      ),
                    )
                  : _mode == _ViewerMode.decoded
                  ? ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: widget.frames.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) =>
                          FrameTile(frame: widget.frames[index]),
                    )
                  : hasUartFrames
                  ? UartWaveformPanel(frames: widget.frames)
                  : const Center(
                      child: Text(
                        'No UART frames in current filter. Switch filter to UART or All.',
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
