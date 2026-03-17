class AnalyzerStatus {
  const AnalyzerStatus({
    required this.connected,
    required this.protocol,
    required this.capturing,
    required this.frames,
    required this.errors,
    required this.deviceName,
  });

  final bool connected;
  final String protocol;
  final bool capturing;
  final int frames;
  final int errors;
  final String deviceName;

  factory AnalyzerStatus.initial() {
    return const AnalyzerStatus(
      connected: false,
      protocol: 'unknown',
      capturing: false,
      frames: 0,
      errors: 0,
      deviceName: '',
    );
  }

  factory AnalyzerStatus.fromJson(Map<String, dynamic> json) {
    return AnalyzerStatus(
      connected: json['connected'] as bool? ?? false,
      protocol: (json['protocol'] as String? ?? 'unknown').toLowerCase(),
      capturing: json['capturing'] as bool? ?? false,
      frames: (json['frames'] as num? ?? 0).toInt(),
      errors: (json['errors'] as num? ?? 0).toInt(),
      deviceName: json['device_name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'connected': connected,
      'protocol': protocol,
      'capturing': capturing,
      'frames': frames,
      'errors': errors,
      'device_name': deviceName,
    };
  }

  AnalyzerStatus copyWith({
    bool? connected,
    String? protocol,
    bool? capturing,
    int? frames,
    int? errors,
    String? deviceName,
  }) {
    return AnalyzerStatus(
      connected: connected ?? this.connected,
      protocol: protocol ?? this.protocol,
      capturing: capturing ?? this.capturing,
      frames: frames ?? this.frames,
      errors: errors ?? this.errors,
      deviceName: deviceName ?? this.deviceName,
    );
  }
}
