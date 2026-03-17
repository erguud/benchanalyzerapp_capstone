import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleConstants {
  BleConstants._();

  static const String deviceNamePrefix = 'BenchAnalyzer-';

  static final Uuid serviceUuid =
      Uuid.parse('12345678-1234-1234-1234-1234567890ab');
  static final Uuid controlCharacteristicUuid =
      Uuid.parse('12345678-1234-1234-1234-1234567890ac');
  static final Uuid statusCharacteristicUuid =
      Uuid.parse('12345678-1234-1234-1234-1234567890ad');
  static final Uuid dataCharacteristicUuid =
      Uuid.parse('12345678-1234-1234-1234-1234567890ae');
  static final Uuid configCharacteristicUuid =
      Uuid.parse('12345678-1234-1234-1234-1234567890af');

  static const int preferredMtu = 247;
}

enum ProtocolKind { uart, i2c, spi, all, unknown }

extension ProtocolKindX on ProtocolKind {
  String get value {
    switch (this) {
      case ProtocolKind.uart:
        return 'uart';
      case ProtocolKind.i2c:
        return 'i2c';
      case ProtocolKind.spi:
        return 'spi';
      case ProtocolKind.all:
        return 'all';
      case ProtocolKind.unknown:
        return 'unknown';
    }
  }

  String get label {
    switch (this) {
      case ProtocolKind.uart:
        return 'UART';
      case ProtocolKind.i2c:
        return 'I2C';
      case ProtocolKind.spi:
        return 'SPI';
      case ProtocolKind.all:
        return 'All';
      case ProtocolKind.unknown:
        return 'Unknown';
    }
  }

  Color get tint {
    switch (this) {
      case ProtocolKind.uart:
        return const Color(0xFF0A66C2);
      case ProtocolKind.i2c:
        return const Color(0xFF2E8B57);
      case ProtocolKind.spi:
        return const Color(0xFFDD7A12);
      case ProtocolKind.all:
      case ProtocolKind.unknown:
        return const Color(0xFF455A64);
    }
  }

  static ProtocolKind fromString(String value) {
    switch (value.toLowerCase()) {
      case 'uart':
        return ProtocolKind.uart;
      case 'i2c':
        return ProtocolKind.i2c;
      case 'spi':
        return ProtocolKind.spi;
      case 'all':
        return ProtocolKind.all;
      default:
        return ProtocolKind.unknown;
    }
  }
}
