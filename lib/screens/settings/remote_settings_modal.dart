import 'package:flutter/material.dart';
import 'package:nexiotcombo/constants.dart';
import 'package:nexiotcombo/services/app_state.dart';

class RemoteSettingsModal extends StatefulWidget {
  const RemoteSettingsModal({super.key});

  @override
  State<RemoteSettingsModal> createState() => _RemoteSettingsModalState();
}

class _RemoteSettingsModalState extends State<RemoteSettingsModal> {
  final _appState = AppState();
  late final TextEditingController _hostCtrl;
  late final TextEditingController _portCtrl;
  late final TextEditingController _pathCtrl;

  @override
  void initState() {
    super.initState();
    _hostCtrl = TextEditingController(text: _appState.serverHost.value ?? '');
    _portCtrl = TextEditingController(text: _appState.serverPort.value ?? '');
    _pathCtrl = TextEditingController(text: _appState.serverPath.value ?? '');
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _pathCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final host = _hostCtrl.text.trim();
    final port = _portCtrl.text.trim();
    final path = _pathCtrl.text.trim();
    if (host.isEmpty) return;
    _appState.serverHost.value = host;
    _appState.serverPort.value = port;
    _appState.serverPath.value = path;
    await _appState.saveServer();
    if (mounted) Navigator.pop(context, 'saved');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: secondaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.cloud_outlined, color: primaryColor, size: 22),
          const SizedBox(width: 8),
          const Text(
            '원격 서버',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Field(label: '호스트', controller: _hostCtrl,
              hint: 'ip 주소 또는 domain 명', keyboardType: TextInputType.url),
          const SizedBox(height: 12),
          _Field(label: '포트', controller: _portCtrl,
              hint: '1883', keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          _Field(label: '경로', controller: _pathCtrl,
              hint: 'iot/iotdemo'),
          const SizedBox(height: 8),
          // URI 미리보기
          ValueListenableBuilder(
            valueListenable: _hostCtrl,
            builder: (_, __, ___) => ValueListenableBuilder(
              valueListenable: _portCtrl,
              builder: (_, __, ___) => ValueListenableBuilder(
                valueListenable: _pathCtrl,
                builder: (_, __, ___) {
                  final h = _hostCtrl.text;
                  final p = _portCtrl.text;
                  final path = _pathCtrl.text;
                  final uri = h.isEmpty ? '' : 'mqtt://$h${p.isEmpty ? '' : ':$p'}${path.isEmpty ? '' : '/$path'}';
                  return Text(
                    uri,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소', style: TextStyle(color: Colors.white54)),
        ),
        TextButton(
          onPressed: _save,
          child: Text('저장', style: TextStyle(color: primaryColor)),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 48,
          child: Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 13, color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
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
          ),
        ),
      ],
    );
  }
}
