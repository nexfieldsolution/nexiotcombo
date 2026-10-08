import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:http/http.dart' as http;
import 'package:nexiotcombo/constants.dart';
import 'app_state.dart';
import 'iot_crypto_service.dart';

class IotConfigService {
  static final IotConfigService _instance = IotConfigService._internal();
  factory IotConfigService() => _instance;
  IotConfigService._internal();

  final _appState = AppState();
  final _crypto = IotCryptoService();


  // ── JSON 조립 ───────────────────────────────────────────────────

  // ESP32 NVS 키와 동일한 필드명으로 JSON 맵 생성
  Map<String, String> buildConfigMap() {
    final map = <String, String>{
      'ssid':        _appState.wifiSsid.value ?? '',
      'password':    _appState.wifiPassword.value ?? '',
      'server_ip':   _appState.serverHost.value ?? '',
      'server_port': _appState.serverPort.value ?? '',
      'server_path': _appState.serverPath.value ?? '',
    };
    if (_appState.apPassword.value != null) {
      map['ap_password'] = _appState.apPassword.value!;
    }
    return map;
  }

  String buildConfigJson() => jsonEncode(buildConfigMap());

  String get adminPassword => _appState.adminPassword.value ?? '';

  // ── BLE 전송 ────────────────────────────────────────────────────
  //
  // 흐름:
  //   ① BLE READ AB4  → nonce 12바이트
  //   ② buildConfigJson() → inner JSON
  //   ③ AES-GCM encrypt(key=SHA256(adminPw)[0:16], nonce)
  //   ④ BLE WRITE AB2 → [nonce:12][tag:16][ciphertext:N]

  Future<void> sendViaBle(BluetoothDevice device) async {
    final services = await device.discoverServices()
        .timeout(const Duration(seconds: 10));

    BluetoothCharacteristic? nonceChar;
    BluetoothCharacteristic? configChar;

    for (final svc in services) {
      for (final chr in svc.characteristics) {
        final uuid = chr.uuid.toString().toLowerCase();
        if (uuid == bleUuidNonce)  nonceChar  = chr;
        if (uuid == bleUuidConfig) configChar = chr;
      }
    }

    if (nonceChar == null)  throw Exception('Nonce characteristic (AB4) not found');
    if (configChar == null) throw Exception('Config characteristic (AB2) not found');

    // ① nonce 12바이트 (binary)
    final nonce = await nonceChar.read();

    // ② 암호화
    final innerJson = buildConfigJson();
    final plain = utf8.encode(innerJson);
    final result = await _crypto.encrypt(plain, nonce, adminPassword);

    debugPrint('[BLE] plain  : $innerJson');
    debugPrint('[BLE] nonce  : ${IotCryptoService.bytesToHex(nonce)}');
    debugPrint('[BLE] tag    : ${IotCryptoService.bytesToHex(result.tag)}');
    debugPrint('[BLE] cipher : ${IotCryptoService.bytesToHex(result.ciphertext)}');
    debugPrint('[BLE] packet : ${nonce.length + result.tag.length + result.ciphertext.length}B');

    // ③ 패킷 조립: [nonce:12][tag:16][ciphertext:N]
    final packet = Uint8List.fromList([...nonce, ...result.tag, ...result.ciphertext]);
    await configChar.write(packet, withoutResponse: false);
  }

  // ── BLE 비밀번호 검증 ──────────────────────────────────────────────
  //
  // {"verify":true} 만 전송 — ESP32가 복호화 성공 시 0, 실패 시 ATT error → 예외

  Future<void> verifyViaBle(BluetoothDevice device, String password) async {
    final services = await device.discoverServices()
        .timeout(const Duration(seconds: 10));

    BluetoothCharacteristic? nonceChar;
    BluetoothCharacteristic? configChar;

    for (final svc in services) {
      for (final chr in svc.characteristics) {
        final uuid = chr.uuid.toString().toLowerCase();
        if (uuid == bleUuidNonce)  nonceChar  = chr;
        if (uuid == bleUuidConfig) configChar = chr;
      }
    }

    if (nonceChar == null)  throw Exception('Nonce characteristic not found');
    if (configChar == null) throw Exception('Config characteristic not found');

    final nonce = await nonceChar.read();
    final plain = utf8.encode('{"auth":"request"}');
    final result = await _crypto.encrypt(plain, nonce, password);

    final packet = Uint8List.fromList([...nonce, ...result.tag, ...result.ciphertext]);
    await configChar.write(packet, withoutResponse: false);
    // 복호화 실패 → ATT error → 예외 발생
  }

  // ── HTTP 전송 (ESP32 AP 모드) ────────────────────────────────────
  //
  // 흐름:
  //   ① GET http://espIp/api/nonce  → {"nonce":"24hex"}
  //   ② buildConfigJson() → inner JSON
  //   ③ AES-GCM encrypt
  //   ④ POST http://espIp/api/wifi/config
  //      body: {"nonce":"hex","enc":"hex","tag":"hex"}

  Future<Map<String, dynamic>> sendViaHttp({String espIp = espApIp}) async {
    // ① nonce 취득
    final nonceResp = await http
        .get(Uri.parse('http://$espIp/api/nonce'))
        .timeout(const Duration(seconds: 5));
    final nonceData = jsonDecode(nonceResp.body) as Map<String, dynamic>;
    final nonceHex = nonceData['nonce'] as String;
    final nonce = IotCryptoService.hexToBytes(nonceHex);

    // ② 암호화
    final innerJson = buildConfigJson();
    final plain = utf8.encode(innerJson);
    final result = await _crypto.encrypt(plain, nonce, adminPassword);

    debugPrint('[HTTP] plain  : $innerJson');
    debugPrint('[HTTP] nonce  : $nonceHex');
    debugPrint('[HTTP] tag    : ${IotCryptoService.bytesToHex(result.tag)}');
    debugPrint('[HTTP] cipher : ${IotCryptoService.bytesToHex(result.ciphertext)}');

    // ③ POST
    final body = jsonEncode({
      'nonce': nonceHex,
      'enc':   IotCryptoService.bytesToHex(result.ciphertext),
      'tag':   IotCryptoService.bytesToHex(result.tag),
    });

    final postResp = await http
        .post(
          Uri.parse('http://$espIp/api/wifi/config'),
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 15));

    return jsonDecode(postResp.body) as Map<String, dynamic>;
  }
}
