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
                  color: accentColor, fontSize: 14, fontWeight: FontWeight.w600),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            ValueListenableBuilder<String?>(
              valueListenable: _appState.btDevice,
              builder: (_, btName, __) {
                if (btName == null) return const SizedBox(height: 8);
                return Column(
                  children: [
                    const SizedBox(height: 8),
                    Center(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 14),
                          children: [
                            TextSpan(
                              text: '${'settings.device'.tr()} : ',
                              style: const TextStyle(color: Colors.white54),
                            ),
                            TextSpan(
                              text: btName,
                              style: const TextStyle(
                                  color: accentColor, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
            Center(
              child: Text(
                'settings.device_settings'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 40),
            ValueListenableBuilder<String?>(
              valueListenable: _appState.btDevice,
              builder: (_, btName, __) => _SettingsItem(
                title: 'settings.bluetooth'.tr(),
                subtitle: btName,
                subtitleColor: accentColor,
                onTap: _showBleModal,
              ),
            ),
            ValueListenableBuilder<String?>(
              valueListenable: _appState.wifiSsid,
              builder: (_, ssid, __) => _SettingsItem(
                title: 'settings.wifi'.tr(),
                subtitle: ssid,
                subtitleColor: accentColor,
                onTap: _showWifiModal,
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
    this.subtitle,
    this.subtitleColor,
  });

  final String title;
  final String? subtitle;
  final Color? subtitleColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Divider(color: Colors.white.withValues(alpha: 0.1), height: 1, thickness: 1),
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: defaultPadding, vertical: 4),
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
