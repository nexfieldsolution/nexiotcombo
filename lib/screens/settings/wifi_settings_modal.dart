import 'package:flutter/material.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:nexiotcombo/constants.dart';
import 'package:nexiotcombo/services/app_state.dart';

class WifiSettingsModal extends StatefulWidget {
  const WifiSettingsModal({super.key});

  @override
  State<WifiSettingsModal> createState() => _WifiSettingsModalState();
}

class _WifiSettingsModalState extends State<WifiSettingsModal> {
  final _appState = AppState();
  List<WiFiAccessPoint> _results = [];
  bool _isScanning = false;
  bool _connecting = false;

  // 관리자 모드: SSID 5초 내 5회 탭 → 비밀번호 저장
  int _tapCount = 0;
  DateTime? _firstTapTime;
  bool _adminSaved = false;

  void _onSsidTap() {
    final now = DateTime.now();
    if (_firstTapTime == null ||
        now.difference(_firstTapTime!) > const Duration(seconds: 5)) {
      _firstTapTime = now;
      _tapCount = 1;
    } else {
      _tapCount++;
    }
    if (_tapCount >= 5 && !_adminSaved) {
      _appState.saveWifi();
      setState(() => _adminSaved = true);
    }
  }

  bool get _isConfigured => _appState.wifiSsid.value != null;

  @override
  void initState() {
    super.initState();
    if (!_isConfigured) _startScan();
  }

  Future<void> _startScan() async {
    setState(() {
      _results = [];
      _isScanning = true;
    });

    final can = await WiFiScan.instance.canStartScan();
    if (can != CanStartScan.yes) {
      if (mounted) setState(() => _isScanning = false);
      return;
    }

    await WiFiScan.instance.startScan();
    final results = await WiFiScan.instance.getScannedResults();
    if (!mounted) return;

    setState(() {
      _results = results
        ..sort((a, b) => b.level.compareTo(a.level));
      _isScanning = false;
    });
  }

  Future<void> _selectNetwork(WiFiAccessPoint ap) async {
    final ssid = ap.ssid;
    if (ssid.isEmpty) return;
    final pw = await _showPasswordDialog(ssid);
    if (pw == null || !mounted) return;
    setState(() => _connecting = true);
    _appState.wifiSsid.value = ssid;
    _appState.wifiPassword.value = pw;
    if (mounted) Navigator.pop(context, 'connected');
  }

  Future<String?> _showPasswordDialog(String ssid) async {
    final ctrl = TextEditingController();
    bool obscure = true;
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: secondaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('비밀번호 입력',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(ssid,
                  style: const TextStyle(color: accentColor, fontSize: 13)),
            ],
          ),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            obscureText: obscure,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: '비밀번호',
              hintStyle: const TextStyle(color: Colors.white38),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: accentColor),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white38,
                  size: 20,
                ),
                onPressed: () => setDlg(() => obscure = !obscure),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: Text('확인', style: TextStyle(color: primaryColor)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _disconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: secondaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: const Text(
          'WiFi 연결을 끊으시겠습니까?',
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
    await _appState.clearWifi();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return _isConfigured ? _buildConfiguredView() : _buildScanView();
  }

  Widget _buildConfiguredView() {
    final ssid = _appState.wifiSsid.value!;
    return AlertDialog(
      backgroundColor: secondaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.wifi, color: primaryColor, size: 22),
          const SizedBox(width: 8),
          const Text(
            'WiFi 연결정보',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _onSsidTap,
            child: Text(
              ssid,
              style: const TextStyle(
                color: accentColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      actions: [
        if (_adminSaved)
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

  Widget _buildScanView() {
    return AlertDialog(
      backgroundColor: secondaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
      title: Row(
        children: [
          Icon(Icons.wifi_find, color: primaryColor, size: 22),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'WiFi 네트워크 검색',
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
        height: 300,
        child: _connecting
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('저장 중...', style: TextStyle(color: Colors.white54)),
                  ],
                ),
              )
            : _results.isEmpty
                ? Center(
                    child: Text(
                      _isScanning ? '스캔 중...' : 'WiFi 네트워크가 없습니다',
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
                      final ap = _results[i];
                      return ListTile(
                        dense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                        leading: Icon(
                          _wifiIcon(ap.level),
                          color: primaryColor,
                          size: 20,
                        ),
                        title: Text(
                          ap.ssid.isNotEmpty ? ap.ssid : '(숨김 네트워크)',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          '${ap.level} dBm',
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                        onTap: () => _selectNetwork(ap),
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

  IconData _wifiIcon(int level) {
    if (level >= -55) return Icons.wifi;
    if (level >= -70) return Icons.wifi_2_bar;
    return Icons.wifi_1_bar;
  }
}
