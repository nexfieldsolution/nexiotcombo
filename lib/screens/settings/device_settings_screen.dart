import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:nexiotcombo/constants.dart';
import 'package:nexiotcombo/screens/settings/ble_diag_modal.dart';
import 'package:nexiotcombo/screens/settings/ble_settings_modal.dart';
import 'package:nexiotcombo/screens/settings/wifi_diag_modal.dart';
import 'package:nexiotcombo/screens/settings/wifi_settings_modal.dart';
import 'package:nexiotcombo/services/app_state.dart';

class DeviceSettingsScreen extends StatefulWidget {
  const DeviceSettingsScreen({super.key});

  @override
  State<DeviceSettingsScreen> createState() => _DeviceSettingsScreenState();
}

class _DeviceSettingsScreenState extends State<DeviceSettingsScreen> {
  final _appState = AppState();

  void _showCenterToast(String message) {
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
              style: const TextStyle(
                  color: Color(0xFF00A8CC), fontSize: 14, fontWeight: FontWeight.w400),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2), () => entry.remove());
  }

  void _showBleModal() async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const BleSettingsModal(),
    );
    if (!mounted) return;
    setState(() {});
    if (result == 'connected') {
      _showCenterToast('블루투스 장치가 연결되었습니다');
    } else if (result == 'diag') {
      _showDiagModal();
    }
  }

  void _showDiagModal() {
    final device = _appState.btDeviceObj.value;
    if (device == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BleDiagModal(device: device),
    );
  }

  void _showWifiModal() async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const WifiSettingsModal(),
    );
    if (!mounted) return;
    setState(() {});
    if (result == 'connected') {
      final ssid = _appState.wifiSsid.value;
      _showCenterToast(ssid != null ? "'$ssid' 에 연결되었습니다" : 'WiFi가 연결되었습니다');
    } else if (result == 'diag') {
      _showWifiDiagModal();
    }
  }

  void _showWifiDiagModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const WifiDiagModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── 헤더 ──────────────────────────────────────
            Container(
              color: secondaryColor,
              padding: const EdgeInsets.only(
                  left: defaultPadding,
                  right: defaultPadding + 8,
                  top: 16,
                  bottom: 16),
              child: Row(
                children: [
                  Image.asset('assets/images/logo.png', width: 34, height: 34),
                  const SizedBox(width: 8),
                  Text.rich(
                    TextSpan(children: [
                      const TextSpan(
                          text: 'NEX',
                          style: TextStyle(color: accentBlueColor)),
                      const TextSpan(
                          text: 'IOT',
                          style: TextStyle(color: Colors.orange)),
                    ]),
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'settings.device_settings'.tr(),
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Image.asset('assets/icons/ic_nav_back.png',
                        width: 32, height: 32),
                  ),
                ],
              ),
            ),
            // ── 컨텐츠 ────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  ValueListenableBuilder<String?>(
                    valueListenable: _appState.btDevice,
                    builder: (_, btName, __) => _SettingsItem(
                      icon: Icons.bluetooth,
                      title: 'settings.device_bluetooth_settings'.tr(),
                      subtitle: btName,
                      subtitleColor: accentColor,
                      showTopDivider: false,
                      onTap: _showBleModal,
                    ),
                  ),
                  ValueListenableBuilder<String?>(
                    valueListenable: _appState.wifiSsid,
                    builder: (_, ssid, __) => _SettingsItem(
                      icon: Icons.cloud_outlined,
                      title: 'settings.device_wifi_settings'.tr(),
                      subtitle: ssid,
                      subtitleColor: accentColor,
                      onTap: _showWifiModal,
                    ),
                  ),
                ],
              ),
            ),
            // ── 바텀바 ────────────────────────────────────
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: secondaryColor,
                border: Border(
                    top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.title,
    required this.onTap,
    this.icon,
    this.subtitle,
    this.subtitleColor,
    this.showTopDivider = true,
  });

  final IconData? icon;
  final String title;
  final String? subtitle;
  final Color? subtitleColor;
  final bool showTopDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showTopDivider)
          Divider(color: Colors.white.withValues(alpha: 0.1), height: 1, thickness: 1),
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: defaultPadding, vertical: 4),
          leading: icon != null
              ? Icon(icon, color: Colors.white54, size: 22)
              : null,
          title: Text(
            title,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          ),
          subtitle: subtitle != null
              ? Text(subtitle!,
                  style: TextStyle(
                      color: subtitleColor ?? Colors.white38, fontSize: 13))
              : null,
          trailing: const Icon(Icons.chevron_right, color: Colors.white38),
          onTap: onTap,
        ),
      ],
    );
  }
}
