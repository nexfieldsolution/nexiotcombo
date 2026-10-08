import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  final btDevice = ValueNotifier<String?>(null);
  final btDeviceObj = ValueNotifier<BluetoothDevice?>(null);

  final wifiSsid = ValueNotifier<String?>(null);
  final wifiPassword = ValueNotifier<String?>(null);
  final apPassword = ValueNotifier<String?>(null);

  final serverHost = ValueNotifier<String?>('192.168.1.1');
  final serverPort = ValueNotifier<String?>('1883');
  final serverPath = ValueNotifier<String?>('iot/iotdemo');

  final adminPassword = ValueNotifier<String?>('iotdev1!');

  Future<void> loadSavedWifi() async {
    final prefs = await SharedPreferences.getInstance();
    final ssid = prefs.getString('wifi_ssid');
    final pw = prefs.getString('wifi_password');
    if (ssid != null) {
      wifiSsid.value = ssid;
      wifiPassword.value = pw;
    }
    final adminPw = prefs.getString('admin_password');
    if (adminPw != null) adminPassword.value = adminPw;
  }

  Future<void> loadSavedServer() async {
    final prefs = await SharedPreferences.getInstance();
    serverHost.value = prefs.getString('server_host') ?? '192.168.1.1';
    serverPort.value = prefs.getString('server_port') ?? '1883';
    serverPath.value = prefs.getString('server_path') ?? 'iot/iotdemo';
  }

  Future<void> saveServer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_host', serverHost.value ?? '');
    await prefs.setString('server_port', serverPort.value ?? '');
    await prefs.setString('server_path', serverPath.value ?? '');
  }

  Future<void> saveWifi() async {
    final prefs = await SharedPreferences.getInstance();
    if (wifiSsid.value != null) {
      await prefs.setString('wifi_ssid', wifiSsid.value!);
      await prefs.setString('wifi_password', wifiPassword.value ?? '');
    }
  }

  Future<void> saveAdminPassword(String pw) async {
    adminPassword.value = pw;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin_password', pw);
  }

  Future<void> clearWifi() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('wifi_ssid');
    await prefs.remove('wifi_password');
    wifiSsid.value = null;
    wifiPassword.value = null;
  }
}
