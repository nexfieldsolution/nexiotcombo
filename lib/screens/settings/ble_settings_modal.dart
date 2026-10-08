import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:nexiotcombo/constants.dart';
import 'package:nexiotcombo/services/app_state.dart';
import 'package:nexiotcombo/services/iot_config_service.dart';
import 'package:permission_handler/permission_handler.dart';

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

  void _showCenterToast(String message, {Color color = Colors.redAccent}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: secondaryColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white38),
            ),
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w400),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2), () => entry.remove());
  }

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

  void _startScan() async {
    // 폰 시스템에서 연결된 iotdev가 있으면 먼저 해제
    for (final d in FlutterBluePlus.connectedDevices) {
      if (d.platformName.toLowerCase().contains('iot')) {
        await d.disconnect();
      }
    }

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
        _results.addAll(results.where((r) {
          final name = r.device.platformName.toLowerCase();
          final advName = r.advertisementData.advName.toLowerCase();
          return name.contains('iot') || advName.contains('iot');
        }));
      });
    });

    _stateSub = FlutterBluePlus.isScanning.listen((scanning) {
      if (!mounted) return;
      setState(() => _isScanning = scanning);
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isScanning = false);
      if (e is PlatformException) _showLocationDialog();
    }
  }

  Future<void> _showLocationDialog() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: secondaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(
          'ble.location_permission'.tr(),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('common.cancel'.tr(), style: const TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('common.ok'.tr(), style: const TextStyle(color: accentBlueColor)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final status = await Permission.location.request();
    if (!mounted) return;
    if (status.isGranted) {
      _startScan(); // GPS 꺼져 있으면 startScan이 다시 _showLocationDialog 호출
    } else {
      _showLocationDialog(); // 권한 거부 시 다시 팝업
    }
  }

  Future<void> _connectTo(ScanResult result) async {
    await FlutterBluePlus.stopScan();
    setState(() => _connecting = true);
    try {
      await result.device.connect(license: License.nonprofit, autoConnect: false);
      final name = result.advertisementData.advName.isNotEmpty
          ? result.advertisementData.advName
          : result.device.platformName.isNotEmpty
              ? result.device.platformName
              : result.device.remoteId.str;
      _appState.btDevice.value = name;
      _appState.btDeviceObj.value = result.device;

      // 물리적 연결 직후 — 비밀번호 확인/설정
      bool authOk = false;
      if (mounted) {
        if (_appState.adminPassword.value != null) {
          // 재연결 — 비밀번호 입력 후 BLE로 검증
          authOk = await _showPasswordVerify(name, result.device);
        } else {
          // 첫 연결 — 비밀번호 설정 후 BLE 전송
          await _showPasswordSetup(name, result.device);
          authOk = _appState.apPassword.value != null;
        }
      }

      if (!authOk) {
        await result.device.disconnect();
        _appState.btDevice.value = null;
        _appState.btDeviceObj.value = null;
        if (mounted) setState(() => _connecting = false);
        return;
      }

      if (mounted) Navigator.pop(context, 'connected');
    } catch (e) {
      debugPrint('[BLE] connect failed: $e');
      if (!mounted) return;
      setState(() => _connecting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ble.connect_fail'.tr()),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<bool> _showPasswordVerify(String deviceName, BluetoothDevice device) async {
    final ctrl = TextEditingController();
    bool obscure = true;
    String? errorText;

    final pw = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: secondaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ble.pw_setup_title'.tr(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(deviceName, style: const TextStyle(color: accentColor, fontSize: 13)),
            ],
          ),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            obscureText: obscure,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'ble.pw_hint'.tr(),
              hintStyle: const TextStyle(color: Colors.white38),
              errorText: errorText,
              errorStyle: const TextStyle(color: Colors.redAccent),
              enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: accentBlueColor)),
              errorBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.redAccent)),
              focusedErrorBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.redAccent)),
              suffixIcon: IconButton(
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white38, size: 20),
                onPressed: () => setDlg(() => obscure = !obscure),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('common.cancel'.tr(), style: const TextStyle(color: Colors.white38)),
            ),
            TextButton(
              onPressed: () {
                if (ctrl.text.isEmpty) {
                  setDlg(() => errorText = 'ble.pw_required'.tr());
                  return;
                }
                Navigator.pop(ctx, ctrl.text);
              },
              child: Text('common.ok'.tr(), style: TextStyle(color: accentBlueColor)),
            ),
          ],
        ),
      ),
    );

    if (pw == null || pw.isEmpty) return false;

    try {
      await IotConfigService().verifyViaBle(device, pw);
      _appState.adminPassword.value = pw;
      _appState.apPassword.value = pw;
      return true;
    } catch (e) {
      debugPrint('[BLE] verify failed: $e');
      if (mounted) _showCenterToast('ble.pw_send_fail'.tr());
      return false;
    }
  }

  Future<void> _showPasswordSetup(String deviceName, BluetoothDevice device) async {
    final curCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    bool obscureCur = true;
    bool obscureNew = true;
    String? curError;

    final result = await showDialog<(String, String)>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: secondaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ble.pw_setup_title'.tr(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(deviceName, style: const TextStyle(color: accentColor, fontSize: 13)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: curCtrl,
                autofocus: true,
                obscureText: obscureCur,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'ble.pw_hint'.tr(),
                  hintStyle: const TextStyle(color: Colors.white38),
                  errorText: curError,
                  errorStyle: const TextStyle(color: Colors.redAccent),
                  enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: accentBlueColor)),
                  errorBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.redAccent)),
                  focusedErrorBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.redAccent)),
                  suffixIcon: IconButton(
                    icon: Icon(obscureCur ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white38, size: 20),
                    onPressed: () => setDlg(() => obscureCur = !obscureCur),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newCtrl,
                obscureText: obscureNew,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'ble.new_pw_hint'.tr(),
                  hintStyle: const TextStyle(color: Colors.white38),
                  enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: accentBlueColor)),
                  suffixIcon: IconButton(
                    icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white38, size: 20),
                    onPressed: () => setDlg(() => obscureNew = !obscureNew),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('common.cancel'.tr(), style: const TextStyle(color: Colors.white38)),
            ),
            TextButton(
              onPressed: () {
                bool valid = true;
                if (curCtrl.text.isEmpty) {
                  setDlg(() => curError = 'ble.pw_required'.tr());
                  valid = false;
                } else {
                  setDlg(() => curError = null);
                }
                if (newCtrl.text.length < 8) {
                  _showCenterToast('ble.pw_min_length'.tr());
                  valid = false;
                }
                if (valid) Navigator.pop(ctx, (curCtrl.text, newCtrl.text));
              },
              child: Text('common.ok'.tr(), style: TextStyle(color: accentBlueColor)),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;
    final (curPw, newPw) = result;

    // 현재 비밀번호를 AES 키로 사용해서 전송
    _appState.adminPassword.value = curPw;
    _appState.apPassword.value = newPw;
    try {
      await IotConfigService().sendViaBle(device);
      _appState.adminPassword.value = newPw;
    } catch (e) {
      debugPrint('[BLE] AP password send failed: $e');
      _appState.adminPassword.value = null;
      _appState.apPassword.value = null;
      if (mounted) _showCenterToast('ble.pw_send_fail'.tr());
    }
  }

  Future<void> _disconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: secondaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(
          'ble.disconnect_confirm'.tr(),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('common.cancel'.tr(), style: const TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('common.ok'.tr(), style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final device = _appState.btDeviceObj.value;
    if (device != null) await device.disconnect();
    _appState.btDevice.value = null;
    _appState.btDeviceObj.value = null;
    _appState.apPassword.value = null;
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
          Text(
            'ble.connected_title'.tr(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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
            child: Text('ble.diagnose'.tr(), style: const TextStyle(color: accentColor)),
          ),
        TextButton(
          onPressed: _disconnect,
          child: Text('ble.disconnect'.tr(), style: const TextStyle(color: Colors.redAccent)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('common.ok'.tr(), style: TextStyle(color: primaryColor)),
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
          Expanded(
            child: Text(
              'ble.scan_title'.tr(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text('ble.connecting'.tr(), style: const TextStyle(color: Colors.white54)),
                  ],
                ),
              )
            : _results.isEmpty
                ? Center(
                    child: Text(
                      _isScanning ? 'ble.scanning'.tr() : 'ble.no_devices'.tr(),
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
                      final name = r.advertisementData.advName.isNotEmpty
                          ? r.advertisementData.advName
                          : r.device.platformName.isNotEmpty
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
          child: Text('common.cancel'.tr(), style: const TextStyle(color: Colors.white54)),
        ),
      ],
    );
  }
}
