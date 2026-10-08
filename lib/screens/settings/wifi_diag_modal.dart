import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nexiotcombo/constants.dart';
import 'package:nexiotcombo/services/app_state.dart';

class WifiDiagModal extends StatefulWidget {
  const WifiDiagModal({super.key});

  @override
  State<WifiDiagModal> createState() => _WifiDiagModalState();
}

class _WifiDiagModalState extends State<WifiDiagModal> {
  final _appState = AppState();
  final List<String> _log = [];
  bool _testing = false;
  final _hostCtrl = TextEditingController(text: '8.8.8.8');

  @override
  void dispose() {
    _hostCtrl.dispose();
    super.dispose();
  }

  void _addLog(String msg) {
    if (!mounted) return;
    setState(() {
      _log.insert(0, '[${DateTime.now().toString().substring(11, 19)}] $msg');
      if (_log.length > 100) _log.removeLast();
    });
  }

  Future<void> _ping() async {
    final host = _hostCtrl.text.trim();
    if (host.isEmpty || _testing) return;
    setState(() => _testing = true);
    _addLog('PING $host ...');
    try {
      final result = await InternetAddress.lookup(host)
          .timeout(const Duration(seconds: 5));
      if (result.isNotEmpty) {
        _addLog('OK  ${result.first.address}');
      } else {
        _addLog('FAIL: no result');
      }
    } on SocketException catch (e) {
      _addLog('FAIL: ${e.message}');
    } on TimeoutException {
      _addLog('FAIL: timeout');
    } catch (e) {
      _addLog('FAIL: $e');
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ssid = _appState.wifiSsid.value ?? '-';

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Handle
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
                  const Icon(Icons.wifi, color: accentColor, size: 18),
                  const SizedBox(width: 8),
                  Text(ssid,
                      style: const TextStyle(
                          color: accentColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (_testing)
                    const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white38),
                    ),
                ],
              ),
            ),
            Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),

            // Ping 입력 + 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _hostCtrl,
                      style: const TextStyle(fontSize: 13, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'host / IP',
                        hintStyle:
                            const TextStyle(color: Colors.white24, fontSize: 12),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 7),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.15)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: accentColor),
                          borderRadius: BorderRadius.all(Radius.circular(6)),
                        ),
                      ),
                      onSubmitted: (_) => _ping(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _testing ? null : _ping,
                    icon: const Icon(Icons.network_ping, size: 13),
                    label: const Text('PING', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accentColor,
                      side: BorderSide(color: accentColor.withValues(alpha: 0.45)),
                      visualDensity: VisualDensity.compact,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                  ),
                ],
              ),
            ),

            Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),

            // LOG
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
                          child:
                              const Text('clear', style: TextStyle(fontSize: 11)),
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
