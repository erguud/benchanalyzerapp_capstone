import '../ble/ble_constants.dart';

class DecodedFrame {
  const DecodedFrame({
    required this.type,
    required this.protocol,
    required this.timestampUs,
    required this.data,
  });

  final String type;
  final String protocol;
  final int timestampUs;
  final String data;

  ProtocolKind get protocolKind => ProtocolKindX.fromString(protocol);

  factory DecodedFrame.fromJson(Map<String, dynamic> json) {
    return DecodedFrame(
      type: json['type'] as String? ?? 'frame',
      protocol: (json['protocol'] as String? ?? 'unknown').toLowerCase(),
      timestampUs: (json['timestamp_us'] as num? ?? 0).toInt(),
      data: json['data'] as String? ?? '',
    );
  }

  static DecodedFrame? tryFromJson(Map<String, dynamic> json) {
    try {
      if ((json['type'] as String? ?? 'frame') != 'frame') {
        return null;
      }
      return DecodedFrame.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'protocol': protocol,
      'timestamp_us': timestampUs,
      'data': data,
    };
  }
}
