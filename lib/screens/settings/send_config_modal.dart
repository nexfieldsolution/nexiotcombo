import 'package:flutter/material.dart';
import 'package:nexiotcombo/constants.dart';
import 'package:nexiotcombo/services/app_state.dart';
import 'package:nexiotcombo/services/iot_config_service.dart';

class SendConfigModal extends StatefulWidget {
  const SendConfigModal({super.key});

  @override
  State<SendConfigModal> createState() => _SendConfigModalState();
}

class _SendConfigModalState extends State<SendConfigModal> {
  final _appState = AppState();
  final _svc = IotConfigService();
  final _pwCtrl = TextEditingController();

  bool _sending = false;
  bool _obscure = true;
  String? _message;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _pwCtrl.text = _appState.adminPassword.value ?? '';
  }

  @override
  void dispose() {
    _pwCtrl.dispose();
    super.dispose();
  }

  bool get _bleConnected => _appState.btDeviceObj.value?.isConnected == true;

  Future<void> _sendBle() async {
    await _send(() async {
      await _appState.saveAdminPassword(_pwCtrl.text.trim());
      await _svc.sendViaBle(_appState.btDeviceObj.value!);
      return '설정이 BLE로 전송됐습니다';
    });
  }

  Future<void> _sendHttp() async {
    await _send(() async {
      await _appState.saveAdminPassword(_pwCtrl.text.trim());
      final resp = await _svc.sendViaHttp();
      final msg = resp['message'] as String? ?? '';
      if (resp['success'] != true) throw Exception(msg);
      return msg.isNotEmpty ? msg : '설정이 저장됐습니다';
    });
  }

  Future<void> _send(Future<String> Function() action) async {
    final pw = _pwCtrl.text.trim();
    if (pw.isEmpty) {
      setState(() { _message = '관리자 비밀번호를 입력하세요'; _success = false; });
      return;
    }
    setState(() { _sending = true; _message = null; });
    try {
      final msg = await action();
      if (mounted) setState(() { _success = true; _message = msg; _sending = false; });
    } catch (e) {
      if (mounted) setState(() { _success = false; _message = e.toString(); _sending = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _svc.buildConfigMap();

    return AlertDialog(
      backgroundColor: secondaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.send_rounded, color: primaryColor, size: 20),
          const SizedBox(width: 8),
          const Text('ESP32 설정 전송',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 전송할 설정 미리보기
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: config.entries
                    .where((e) => e.key != 'password')
                    .map((e) => Text(
                          '${e.key}: ${e.value.isEmpty ? "(미설정)" : e.value}',
                          style: TextStyle(
                            color: e.value.isEmpty ? Colors.white24 : Colors.white60,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 14),

            // 관리자 비밀번호
            const Text('관리자 비밀번호',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: _pwCtrl,
              obscureText: _obscure,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                hintText: '기본: iotdev1!',
                hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(6),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: accentColor),
                  borderRadius: BorderRadius.all(Radius.circular(6)),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white38, size: 18,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),

            // 결과 메시지
            if (_message != null) ...[
              const SizedBox(height: 10),
              Text(
                _message!,
                style: TextStyle(
                  color: _success ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 12,
                ),
              ),
            ],

            if (_sending) ...[
              const SizedBox(height: 12),
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ],
        ),
      ),
      actions: _sending
          ? []
          : [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('닫기', style: TextStyle(color: Colors.white38)),
              ),
              if (_bleConnected)
                TextButton(
                  onPressed: _sendBle,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bluetooth, size: 14, color: primaryColor),
                      const SizedBox(width: 4),
                      Text('BLE 전송', style: TextStyle(color: primaryColor)),
                    ],
                  ),
                ),
              TextButton(
                onPressed: _sendHttp,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi, size: 14, color: accentColor),
                    const SizedBox(width: 4),
                    const Text('AP 전송', style: TextStyle(color: accentColor)),
                  ],
                ),
              ),
            ],
    );
  }
}
