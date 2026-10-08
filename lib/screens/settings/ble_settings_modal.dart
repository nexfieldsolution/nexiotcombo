import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:nexiotcombo/constants.dart';
import 'package:nexiotcombo/services/app_state.dart';

class BleSettingsModal extends StatefulWidget {
  const BleSettingsModal({super.key});

  @override
  State<BleSettingsModal> createState() => _BleSettingsModalState();
}

class _BleSettingsModalState extends State<BleSettingsModal> {
  final _appState = AppState();
  final List<ScanResult> _results = [];
  bool _isScanning = false;
  bool _connecting = false;
  StreamSubscription? _scanSub;
  StreamSubscription? _stateSub;

  // 관리자 모드 트리거: 장치명 5초 내 5회 탭
  int _tapCount = 0;
  DateTime? _firstTapTime;
  bool _adminVisible = false;

  void _onDeviceNameTap() {
    final now = DateTime.now();
    if (_firstTapTime == null ||
        now.difference(_firstTapTime!) > const Duration(seconds: 5)) {
      _firstTapTime = now;
      _tapCount = 1;
    } else {
      _tapCount++;
    }
    if (_tapCount >= 5 && !_adminVisible) {
      setState(() => _adminVisible = true);
    }
  }

  bool get _isConnected {
    final dev = _appState.btDeviceObj.value;
    return dev != null && dev.isConnected;
  }

  @override
  void initState() {
    super.initState();
    if (!_isConnected) _startScan();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _stateSub?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  void _startScan() {
    setState(() {
      _results.clear();
      _isScanning = true;
    });

    _scanSub?.cancel();
    _stateSub?.cancel();

    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      if (!mounted) return;
      setState(() {
        _results.clear();
        _results.addAll(results.where(
          (r) => r.device.platformName.toLowerCase().contains('iot'),
        ));
      });
    });

    _stateSub = FlutterBluePlus.isScanning.listen((scanning) {
      if (!mounted) return;
      setState(() => _isScanning = scanning);
    });

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
  }

  Future<void> _connectTo(ScanResult result) async {
    await FlutterBluePlus.stopScan();
    setState(() => _connecting = true);
    try {
      await result.device.connect(license: License.nonprofit, autoConnect: false);
      final name = result.device.platformName.isNotEmpty
          ? result.device.platformName
          : result.device.remoteId.str;
      _appState.btDevice.value = name;
      _appState.btDeviceObj.value = result.device;
      if (mounted) Navigator.pop(context, 'connected');
    } catch (_) {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _disconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: secondaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: const Text(
          '블루투스 연결을 끊으시겠습니까?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('확인', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final device = _appState.btDeviceObj.value;
    if (device != null) await device.disconnect();
    _appState.btDevice.value = null;
    _appState.btDeviceObj.value = null;
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return _isConnected ? _buildConnectedView() : _buildScanView();
  }

  // ── 연결된 상태 ───────────────────────────────────────────────────────────────

  Widget _buildConnectedView() {
    final device = _appState.btDeviceObj.value!;
    final name = device.platformName.isNotEmpty
        ? device.platformName
        : device.remoteId.str;

    return AlertDialog(
      backgroundColor: secondaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.bluetooth_connected, color: primaryColor, size: 22),
          const SizedBox(width: 8),
          const Text(
            '블루투스 연결정보',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _onDeviceNameTap,
            child: Text(
              name,
              style: const TextStyle(
                color: accentColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            device.remoteId.str,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
      actions: [
        if (_adminVisible)
          TextButton(
            onPressed: () => Navigator.pop(context, 'diag'),
            child: const Text('진단하기', style: TextStyle(color: accentColor)),
          ),
        TextButton(
          onPressed: _disconnect,
          child: const Text('연결끊기', style: TextStyle(color: Colors.redAccent)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('확인', style: TextStyle(color: primaryColor)),
        ),
      ],
    );
  }

  // ── 스캔 상태 ─────────────────────────────────────────────────────────────────

  Widget _buildScanView() {
    return AlertDialog(
      backgroundColor: secondaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
      title: Row(
        children: [
          Icon(Icons.bluetooth_searching, color: primaryColor, size: 22),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '블루투스 기기 검색',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          if (_isScanning)
            const SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38),
            )
          else
            GestureDetector(
              onTap: _startScan,
              child: const Icon(Icons.refresh, color: Colors.white54, size: 20),
            ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 260,
        child: _connecting
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('연결 중...', style: TextStyle(color: Colors.white54)),
                  ],
                ),
              )
            : _results.isEmpty
                ? Center(
                    child: Text(
                      _isScanning ? '스캔 중...' : 'IoT 기기가 없습니다',
                      style: const TextStyle(color: Colors.white38, fontSize: 14),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => Divider(
                      color: Colors.white.withValues(alpha: 0.08),
                      height: 1,
                    ),
                    itemBuilder: (_, i) {
                      final r = _results[i];
                      final name = r.device.platformName.isNotEmpty
                          ? r.device.platformName
                          : r.device.remoteId.str;
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                        leading: Icon(Icons.bluetooth, color: primaryColor, size: 20),
                        title: Text(
                          name,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          '${r.device.remoteId.str}  ${r.rssi} dBm',
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                        onTap: () => _connectTo(r),
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소', style: TextStyle(color: Colors.white54)),
        ),
      ],
    );
  }
}
