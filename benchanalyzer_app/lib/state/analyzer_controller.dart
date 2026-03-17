import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../ble/ble_constants.dart';
import '../ble/ble_service.dart';
import '../models/analyzer_status.dart';
import '../models/decoded_frame.dart';

class AnalyzerController extends ChangeNotifier {
  AnalyzerController(this._bleService) {
    _bleStatusSub = _bleService.bleStatusStream.listen(_handleBleStatus);
  }

  final BleService _bleService;

  static const int maxFrameBuffer = 100;
  static const int _maxReconnectAttempts = 5;

  StreamSubscription<List<DiscoveredDevice>>? _scanSub;
  StreamSubscription<ConnectionStateUpdate>? _connectionSub;
  StreamSubscription<Map<String, dynamic>>? _frameSub;
  StreamSubscription<BleStatus>? _bleStatusSub;
  Timer? _reconnectTimer;

  final List<DiscoveredDevice> _scanResults = [];
  final List<DecodedFrame> _frames = [];

  bool _isScanning = false;
  String? _errorMessage;
  DiscoveredDevice? _selectedDevice;
  DeviceConnectionState _connectionState = DeviceConnectionState.disconnected;
  AnalyzerStatus _status = AnalyzerStatus.initial();
  ProtocolKind _activeFilter = ProtocolKind.all;
  int _totalFramesReceived = 0;
  bool _autoReconnect = true;
  bool _manualDisconnectRequested = false;
  int _reconnectAttempt = 0;
  bool _isReconnecting = false;
  String _bleStatusName = 'unknown';

  List<DiscoveredDevice> get scanResults => List.unmodifiable(_scanResults);
  bool get isScanning => _isScanning;
  String? get errorMessage => _errorMessage;
  DiscoveredDevice? get selectedDevice => _selectedDevice;
  DeviceConnectionState get connectionState => _connectionState;
  AnalyzerStatus get status => _status;
  ProtocolKind get activeFilter => _activeFilter;
  int get totalFramesReceived => _totalFramesReceived;
  bool get isConnected => _connectionState == DeviceConnectionState.connected;
  bool get autoReconnect => _autoReconnect;
  bool get isReconnecting => _isReconnecting;
  int get reconnectAttempt => _reconnectAttempt;
  String get bleStatusName => _bleStatusName;
  bool get isMobileTarget => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  bool get isBleReady => isMobileTarget && _bleStatusName == 'ready';
  String? get bleStatusGuidance {
    if (!isMobileTarget) {
      return 'BLE requires a physical iOS or Android device. '
          'Connect your phone and run: flutter run -d <device_id>';
    }
    switch (_bleStatusName) {
      case 'ready':
        return null;
      case 'poweredOff':
      case 'poweredoff':
        return 'Bluetooth is turned off. Enable Bluetooth and retry scanning.';
      case 'unauthorized':
        return 'Bluetooth permission is not granted. Allow Bluetooth permissions in system settings.';
      case 'locationservicesdisabled':
        return 'Location services are disabled. Enable them so BLE scan can discover devices.';
      case 'unsupported':
        return 'Bluetooth LE is unsupported on this device.';
      default:
        return 'Bluetooth is not ready yet. Wait a moment and try scanning again.';
    }
  }

  List<DecodedFrame> get filteredFrames {
    if (_activeFilter == ProtocolKind.all) {
      return List.unmodifiable(_frames);
    }

    return List.unmodifiable(
      _frames.where((frame) => frame.protocolKind == _activeFilter),
    );
  }

  Future<void> startScan() async {
    if (!isBleReady) {
      _isScanning = false;
      _errorMessage = bleStatusGuidance;
      notifyListeners();
      return;
    }

    await _scanSub?.cancel();
    _scanResults.clear();
    _isScanning = true;
    _errorMessage = null;
    notifyListeners();

    _scanSub = _bleService.scanForBenchAnalyzerDevices().listen(
      (devices) {
        _scanResults
          ..clear()
          ..addAll(devices);
        notifyListeners();
      },
      onError: (Object error) {
        _isScanning = false;
        _errorMessage = 'Scan failed: $error';
        notifyListeners();
      },
      onDone: () {
        _isScanning = false;
        notifyListeners();
      },
    );
  }

  Future<void> stopScan() async {
    await _scanSub?.cancel();
    _scanSub = null;
    _isScanning = false;
    notifyListeners();
  }

  Future<void> connectToDevice(DiscoveredDevice device) async {
    await stopScan();
    await _tearDownConnectionState();
    _reconnectTimer?.cancel();

    _selectedDevice = device;
    _connectionState = DeviceConnectionState.connecting;
    _errorMessage = null;
    _manualDisconnectRequested = false;
    _isReconnecting = false;
    notifyListeners();

    _connectionSub = _bleService.connectToDevice(device.id).listen(
      (update) {
        _connectionState = update.connectionState;
        notifyListeners();

        if (update.connectionState == DeviceConnectionState.connected) {
          _reconnectAttempt = 0;
          _isReconnecting = false;
          _errorMessage = null;
          _onConnected(update.deviceId);
        }

        if (update.connectionState == DeviceConnectionState.disconnected) {
          unawaited(_onDisconnected(unexpected: !_manualDisconnectRequested));
        }
      },
      onError: (Object error) {
        _errorMessage = 'Connection failed: $error';
        _connectionState = DeviceConnectionState.disconnected;
        if (_autoReconnect && !_manualDisconnectRequested) {
          _scheduleReconnect();
        }
        notifyListeners();
      },
    );
  }

  Future<void> disconnect() async {
    final deviceId = _selectedDevice?.id;
    _manualDisconnectRequested = true;
    _isReconnecting = false;
    _reconnectTimer?.cancel();

    await _tearDownConnectionState();
    _connectionState = DeviceConnectionState.disconnected;
    _status = _status.copyWith(connected: false, capturing: false);

    if (deviceId != null) {
      await _bleService.disconnectDevice(deviceId);
    }

    notifyListeners();
  }

  Future<void> reconnect() async {
    final selected = _selectedDevice;
    if (selected == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
    await connectToDevice(selected);
  }

  void setAutoReconnect(bool value) {
    _autoReconnect = value;
    if (!value) {
      _isReconnecting = false;
      _reconnectTimer?.cancel();
    }
    notifyListeners();
  }

  Future<void> sendPing() => _sendCommand({'cmd': 'ping'});

  Future<void> refreshStatus() async {
    final deviceId = _selectedDevice?.id;
    if (deviceId == null || !isConnected) {
      return;
    }

    try {
      final json = await _bleService.readStatusJson(deviceId);
      if (json != null) {
        _status = AnalyzerStatus.fromJson(json).copyWith(
          deviceName: _status.deviceName.isEmpty
              ? (_selectedDevice?.name ?? '')
              : _status.deviceName,
        );
        notifyListeners();
      }
    } catch (error) {
      _errorMessage = 'Status read failed: $error';
      notifyListeners();
    }
  }

  Future<void> setProtocol(ProtocolKind protocol) async {
    if (protocol == ProtocolKind.all || protocol == ProtocolKind.unknown) {
      return;
    }

    await _sendCommand({'cmd': 'set_protocol', 'value': protocol.value});
    _status = _status.copyWith(protocol: protocol.value);
    notifyListeners();
  }

  Future<void> startCapture() async {
    await _sendCommand({'cmd': 'start_capture'});
    _status = _status.copyWith(capturing: true);
    notifyListeners();
  }

  Future<void> stopCapture() async {
    await _sendCommand({'cmd': 'stop_capture'});
    _status = _status.copyWith(capturing: false);
    notifyListeners();
  }

  Future<void> clearFrames({bool clearDeviceFrames = true}) async {
    _frames.clear();
    _totalFramesReceived = 0;

    if (clearDeviceFrames) {
      await _sendCommand({'cmd': 'clear_frames'});
    }

    notifyListeners();
  }

  void setFilter(ProtocolKind filter) {
    _activeFilter = filter;
    notifyListeners();
  }

  Future<void> _sendCommand(Map<String, dynamic> command) async {
    final deviceId = _selectedDevice?.id;
    if (deviceId == null || !isConnected) {
      return;
    }

    try {
      await _bleService.writeControlCommand(deviceId, command);
    } catch (error) {
      _errorMessage = 'Command failed: $error';
      notifyListeners();
    }
  }

  Future<void> _onConnected(String deviceId) async {
    try {
      await _bleService.requestMtu(deviceId);
    } catch (_) {
      // MTU request can fail on some stacks but data flow can still continue.
    }

    _status = _status.copyWith(
      connected: true,
      deviceName: _selectedDevice?.name ?? _status.deviceName,
    );
    notifyListeners();

    await refreshStatus();

    await _frameSub?.cancel();
    _frameSub = _bleService.subscribeToDataFrames(deviceId).listen(
      (json) {
        final frame = DecodedFrame.tryFromJson(json);
        if (frame == null) {
          return;
        }

        _frames.insert(0, frame);
        if (_frames.length > maxFrameBuffer) {
          _frames.removeRange(maxFrameBuffer, _frames.length);
        }

        _totalFramesReceived++;
        notifyListeners();
      },
      onError: (Object error) {
        _errorMessage = 'Data stream error: $error';
        notifyListeners();
      },
    );
  }

  Future<void> _onDisconnected({required bool unexpected}) async {
    await _frameSub?.cancel();
    _frameSub = null;
    await _connectionSub?.cancel();
    _connectionSub = null;

    _status = _status.copyWith(connected: false, capturing: false);
    if (unexpected) {
      _errorMessage = 'Connection lost. Attempting recovery...';
      _scheduleReconnect();
    }
    notifyListeners();
  }

  void _scheduleReconnect() {
    final selected = _selectedDevice;
    if (!_autoReconnect || _manualDisconnectRequested || selected == null) {
      _isReconnecting = false;
      return;
    }

    if (_reconnectAttempt >= _maxReconnectAttempts) {
      _isReconnecting = false;
      _errorMessage =
          'Reconnect attempts exhausted. Tap Reconnect to try again.';
      notifyListeners();
      return;
    }

    _reconnectAttempt += 1;
    _isReconnecting = true;
    final backoffSeconds = _reconnectAttempt.clamp(1, 4);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: backoffSeconds), () {
      reconnect();
    });
    notifyListeners();
  }

  void _handleBleStatus(BleStatus status) {
    final name = _bleStatusToName(status);
    final changed = name != _bleStatusName;
    _bleStatusName = name;

    if (!isBleReady && _isScanning) {
      _scanSub?.cancel();
      _scanSub = null;
      _isScanning = false;
      _errorMessage = bleStatusGuidance;
    }

    if (isBleReady && _errorMessage == bleStatusGuidance) {
      _errorMessage = null;
    }

    if (changed) {
      notifyListeners();
    }
  }

  String _bleStatusToName(BleStatus status) {
    final text = status.toString();
    final dot = text.indexOf('.');
    if (dot >= 0 && dot + 1 < text.length) {
      return text.substring(dot + 1);
    }
    return text;
  }

  Future<void> _tearDownConnectionState() async {
    _reconnectTimer?.cancel();

    await _frameSub?.cancel();
    _frameSub = null;

    await _connectionSub?.cancel();
    _connectionSub = null;
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _bleStatusSub?.cancel();
    _scanSub?.cancel();
    _connectionSub?.cancel();
    _frameSub?.cancel();
    super.dispose();
  }
}
