import 'dart:convert';
import 'package:cryptography/cryptography.dart';

class IotCryptoService {
  static final IotCryptoService _instance = IotCryptoService._internal();
  factory IotCryptoService() => _instance;
  IotCryptoService._internal();

  // key = SHA256(adminPassword)[0:16]
  Future<List<int>> deriveKey(String password) async {
    final hash = await Sha256().hash(utf8.encode(password));
    return hash.bytes.sublist(0, 16);
  }

  // AES-GCM-128, 12-byte nonce (GCM standard)
  // Returns ({ciphertext, tag}) — nonce is provided by caller (from ESP32)
  Future<({List<int> ciphertext, List<int> tag})> encrypt(
    List<int> plaintext,
    List<int> nonce,       // 12 bytes from ESP32
    String adminPassword,
  ) async {
    final keyBytes = await deriveKey(adminPassword);
    final algorithm = AesGcm.with128bits();
    final secretKey = await algorithm.newSecretKeyFromBytes(keyBytes);

    final secretBox = await algorithm.encrypt(
      plaintext,
      secretKey: secretKey,
      nonce: nonce,
    );

    return (ciphertext: secretBox.cipherText, tag: secretBox.mac.bytes);
  }

  static List<int> hexToBytes(String hex) {
    final result = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      result.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return result;
  }

  static String bytesToHex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
