import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:nexiotcombo/constants.dart';
import 'package:nexiotcombo/services/app_state.dart';
import 'package:nexiotcombo/services/iot_config_service.dart';

class BleDiagModal extends StatefulWidget {
  final BluetoothDevice device;
  const BleDiagModal({super.key, required this.device});

  @override
  State<BleDiagModal> createState() => _BleDiagModalState();
}

class _BleDiagModalState extends State<BleDiagModal> {
  final _appState = AppState();
  final _svc = IotConfigService();
  final _pwCtrl = TextEditingController();

  List<BluetoothCharacteristic> _chars = [];
  final List<String> _log = [];
  bool _loading = false;
  bool _sending = false;
  bool _obscure = true;
  StreamSubscription? _connSub;

  @override
  void initState() {
    super.initState();
    _pwCtrl.text = _appState.adminPassword.value ?? '';
    // 이미 연결된 상태로 진입 → 즉시 서비스 탐색
    _loadChars();
    // 혹시 연결이 끊겼다 재연결될 경우 대비
    _connSub = widget.device.connectionState.listen((s) {
      if (!mounted) return;
      if (s == BluetoothConnectionState.connected && _chars.isEmpty) {
        _loadChars();
      }
    });
  }

  @override
  void dispose() {
    _pwCtrl.dispose();
    _connSub?.cancel();
    super.dispose();
  }

  Future<void> _loadChars() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final services = await widget.device
          .discoverServices()
          .timeout(const Duration(seconds: 10));
      final all = <BluetoothCharacteristic>[];
      for (final s in services) {
        for (final c in s.characteristics) {
          final uuid = c.uuid.toString().toLowerCase();
          // 커스텀 UUID: 128-bit 전체 형식(36자)이면서 표준 BT SIG suffix 없는 것만
          final isCustom = uuid.length == 36 &&
              !uuid.endsWith('-0000-1000-8000-00805f9b34fb');
          if (isCustom) all.add(c);
        }
      }
      if (mounted) setState(() => _chars = all.isEmpty ? [] : [all.first]);
    } catch (e) {
      if (mounted) _addLog('서비스 탐색 실패: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _addLog(String msg) {
    if (!mounted) return;
    setState(() {
      _log.insert(0, '[${DateTime.now().toString().substring(11, 19)}] $msg');
      if (_log.length > 100) _log.removeLast();
    });
  }

  Future<void> _sendConfig() async {
    final pw = _pwCtrl.text.trim();
    if (pw.isEmpty) {
      _addLog('관리자 비밀번호를 입력하세요');
      return;
    }
    setState(() => _sending = true);
    try {
      await _appState.saveAdminPassword(pw);
      await _svc.sendViaBle(widget.device);
      _addLog('설정 전송 완료');
    } catch (e) {
      _addLog('전송 실패: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.device.platformName.isNotEmpty
        ? widget.device.platformName
        : widget.device.remoteId.str;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
              child: Row(
                children: [
                  const Icon(Icons.bluetooth_connected, color: accentColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    name,
                    style: const TextStyle(
                      color: accentColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (_loading)
                    const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white38, size: 20),
                      onPressed: _loadChars,
                      tooltip: '새로고침',
                    ),
                ],
              ),
            ),
            Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),

            // Characteristic — 단일 카드
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: _chars.isEmpty
                  ? Center(
                      child: _loading
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 14, height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white38),
                                ),
                                SizedBox(width: 8),
                                Text('읽는 중...',
                                    style: TextStyle(color: Colors.white38, fontSize: 13)),
                              ],
                            )
                          : const Text('특성 없음',
                              style: TextStyle(color: Colors.white38)),
                    )
                  : _ChrTile(chr: _chars.first, onLog: _addLog),
            ),

            // ── 설정 전송 ───────────────────────────────────────────
            Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ESP32 설정 전송',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _pwCtrl,
                          obscureText: _obscure,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                            hintText: '관리자 비밀번호',
                            hintStyle:
                                const TextStyle(color: Colors.white24, fontSize: 12),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.15)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: accentColor),
                              borderRadius: BorderRadius.all(Radius.circular(6)),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure ? Icons.visibility_off : Icons.visibility,
                                color: Colors.white38,
                                size: 16,
                              ),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _sending
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: accentColor),
                            )
                          : OutlinedButton.icon(
                              onPressed: _sendConfig,
                              icon: const Icon(Icons.send_rounded, size: 13),
                              label: const Text('전송',
                                  style: TextStyle(fontSize: 11)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: accentColor,
                                side: BorderSide(
                                    color: accentColor.withValues(alpha: 0.45)),
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                              ),
                            ),
                    ],
                  ),
                ],
              ),
            ),

            Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),

            // Log — 나머지 전체
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 4, 0),
                    child: Row(
                      children: [
                        const Text('LOG',
                            style: TextStyle(
                                color: Colors.white38,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 1)),
                        const Spacer(),
                        TextButton(
                          onPressed: () => setState(() => _log.clear()),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor: Colors.white24,
                          ),
                          child: const Text('clear', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: secondaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: _log.isEmpty
                          ? const SizedBox()
                          : ListView.builder(
                              itemCount: _log.length,
                              itemBuilder: (_, i) => Text(
                                _log[i],
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                    color: Colors.white60),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Characteristic tile ───────────────────────────────────────────────────────

class _ChrTile extends StatefulWidget {
  const _ChrTile({required this.chr, required this.onLog});
  final BluetoothCharacteristic chr;
  final void Function(String) onLog;

  @override
  State<_ChrTile> createState() => _ChrTileState();
}

class _ChrTileState extends State<_ChrTile> {
  String? _readValue;
  final _writeCtrl = TextEditingController();

  @override
  void dispose() {
    _writeCtrl.dispose();
    super.dispose();
  }

  String _shortUuid(Guid uuid) {
    final s = uuid.toString().toLowerCase();
    if (s.length >= 36 &&
        s.startsWith('0000') &&
        s.endsWith('-0000-1000-8000-00805f9b34fb')) {
      return '0x${s.substring(4, 8).toUpperCase()}';
    }
    if (s.length >= 8) return s.substring(0, 8).toUpperCase();
    return s.toUpperCase();
  }

  Future<void> _read() async {
    try {
      final val = await widget.chr.read();
      final str = utf8.decode(val, allowMalformed: true);
      setState(() => _readValue = str);
      widget.onLog('R [${_shortUuid(widget.chr.uuid)}] "$str"');
    } catch (e) {
      widget.onLog('R error: $e');
    }
  }

  Future<void> _write() async {
    final text = _writeCtrl.text.trim();
    if (text.isEmpty) return;
    try {
      await widget.chr.write(utf8.encode(text), withoutResponse: false);
      widget.onLog('W [${_shortUuid(widget.chr.uuid)}] "$text"');
      _writeCtrl.clear();
    } catch (e) {
      widget.onLog('W error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Read result
          if (_readValue != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('← "$_readValue"',
                  style: const TextStyle(fontSize: 13, color: accentColor)),
            ),

          // READ button
          _btn('READ', Icons.download_outlined, Colors.blue, _read),

          const SizedBox(height: 8),

          // Write input + WRITE button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _writeCtrl,
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'data to write',
                    hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: accentColor),
                      borderRadius: BorderRadius.all(Radius.circular(6)),
                    ),
                  ),
                  onSubmitted: (_) => _write(),
                ),
              ),
              const SizedBox(width: 6),
              _btn('WRITE', Icons.upload_outlined, Colors.green, _write),
            ],
          ),
        ],
      ),
    );
  }

  Widget _btn(String label, IconData icon, Color color, VoidCallback onTap) =>
      OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 13),
        label: Text(label, style: const TextStyle(fontSize: 11)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.45)),
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
      );
}
