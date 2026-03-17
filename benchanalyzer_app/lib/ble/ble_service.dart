import 'dart:async';
import 'dart:convert';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'ble_constants.dart';

class BleService {
  BleService(this._ble);

  final FlutterReactiveBle _ble;

  Stream<BleStatus> get bleStatusStream => _ble.statusStream;

  Stream<List<DiscoveredDevice>> scanForBenchAnalyzerDevices() {
    final devicesById = <String, DiscoveredDevice>{};

    return _ble
        .scanForDevices(
          withServices: [BleConstants.serviceUuid],
          scanMode: ScanMode.lowLatency,
          requireLocationServicesEnabled: false,
        )
        .where(
          (device) =>
              device.name.isNotEmpty &&
              device.name.startsWith(BleConstants.deviceNamePrefix),
        )
        .map((device) {
          devicesById[device.id] = device;
          final list = devicesById.values.toList()
            ..sort((a, b) => a.name.compareTo(b.name));
          return list;
        });
  }

  Stream<ConnectionStateUpdate> connectToDevice(String deviceId) {
    return _ble.connectToDevice(
      id: deviceId,
      connectionTimeout: const Duration(seconds: 15),
      servicesWithCharacteristicsToDiscover: {
        BleConstants.serviceUuid: [
          BleConstants.controlCharacteristicUuid,
          BleConstants.statusCharacteristicUuid,
          BleConstants.dataCharacteristicUuid,
          BleConstants.configCharacteristicUuid,
        ],
      },
    );
  }

  Future<void> disconnectDevice(String deviceId) async {
    // flutter_reactive_ble disconnects when the connection stream is canceled.
    // This method is kept for a clear service API and future extension.
  }

  Future<int> requestMtu(String deviceId, {int mtu = BleConstants.preferredMtu}) {
    return _ble.requestMtu(deviceId: deviceId, mtu: mtu);
  }

  Future<Map<String, dynamic>?> readStatusJson(String deviceId) async {
    final characteristic = _statusCharacteristic(deviceId);
    final bytes = await _ble.readCharacteristic(characteristic);
    return _safeDecodeJsonObject(bytes);
  }

  Future<Map<String, dynamic>?> readConfigJson(String deviceId) async {
    final characteristic = _configCharacteristic(deviceId);
    final bytes = await _ble.readCharacteristic(characteristic);
    return _safeDecodeJsonObject(bytes);
  }

  Future<void> writeControlCommand(String deviceId, Map<String, dynamic> command) {
    final characteristic = _controlCharacteristic(deviceId);
    return _ble.writeCharacteristicWithResponse(
      characteristic,
      value: utf8.encode(jsonEncode(command)),
    );
  }

  Future<void> writeConfig(String deviceId, Map<String, dynamic> config) {
    final characteristic = _configCharacteristic(deviceId);
    return _ble.writeCharacteristicWithResponse(
      characteristic,
      value: utf8.encode(jsonEncode(config)),
    );
  }

  Stream<Map<String, dynamic>> subscribeToDataFrames(String deviceId) async* {
    await for (final payload
        in _ble.subscribeToCharacteristic(_dataCharacteristic(deviceId))) {
      final json = _safeDecodeJsonObject(payload);
      if (json != null) {
        yield json;
      }
    }
  }

  QualifiedCharacteristic _controlCharacteristic(String deviceId) {
    return QualifiedCharacteristic(
      serviceId: BleConstants.serviceUuid,
      characteristicId: BleConstants.controlCharacteristicUuid,
      deviceId: deviceId,
    );
  }

  QualifiedCharacteristic _statusCharacteristic(String deviceId) {
    return QualifiedCharacteristic(
      serviceId: BleConstants.serviceUuid,
      characteristicId: BleConstants.statusCharacteristicUuid,
      deviceId: deviceId,
    );
  }

  QualifiedCharacteristic _dataCharacteristic(String deviceId) {
    return QualifiedCharacteristic(
      serviceId: BleConstants.serviceUuid,
      characteristicId: BleConstants.dataCharacteristicUuid,
      deviceId: deviceId,
    );
  }

  QualifiedCharacteristic _configCharacteristic(String deviceId) {
    return QualifiedCharacteristic(
      serviceId: BleConstants.serviceUuid,
      characteristicId: BleConstants.configCharacteristicUuid,
      deviceId: deviceId,
    );
  }

  Map<String, dynamic>? _safeDecodeJsonObject(List<int> bytes) {
    try {
      final decodedText = utf8.decode(bytes, allowMalformed: true).trim();
      if (decodedText.isEmpty) {
        return null;
      }
      final decodedJson = jsonDecode(decodedText);
      if (decodedJson is Map<String, dynamic>) {
        return decodedJson;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
