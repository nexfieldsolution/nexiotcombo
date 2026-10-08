import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:nexiotcombo/constants.dart';
import 'package:nexiotcombo/screens/settings/device_settings_screen.dart';
import 'package:nexiotcombo/screens/settings/lang_settings_modal.dart';
import 'package:nexiotcombo/screens/settings/remote_settings_modal.dart';
import 'package:nexiotcombo/services/app_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _appState = AppState();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: secondaryColor,
              padding: const EdgeInsets.only(
                  left: defaultPadding, right: defaultPadding + 8, top: 16, bottom: 16),
              child: Row(
                children: [
                  Image.asset('assets/images/logo.png', width: 34, height: 34),
                  const SizedBox(width: 8),
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: 'NEX',
                          style: const TextStyle(color: accentBlueColor)),
                      TextSpan(text: 'IOT',
                          style: const TextStyle(color: Colors.orange)),
                    ]),
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
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
            const SizedBox(height: 16),
            ListenableBuilder(
              listenable: Listenable.merge([_appState.btDevice, _appState.wifiSsid]),
              builder: (_, __) {
                final btName = _appState.btDevice.value;
                final ssid = _appState.wifiSsid.value;
                final hasAny = btName != null || ssid != null;
                return _SettingsItem(
                  icon: Icons.devices_outlined,
                  title: 'settings.device_settings'.tr(),
                  subtitleWidget: hasAny
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (btName != null) ...[
                              const Icon(Icons.bluetooth,
                                  size: 13, color: accentColor),
                              const SizedBox(width: 3),
                              Text(btName,
                                  style: const TextStyle(
                                      color: accentColor, fontSize: 13)),
                            ],
                            if (btName != null && ssid != null)
                              const SizedBox(width: 12),
                            if (ssid != null) ...[
                              const Icon(Icons.wifi,
                                  size: 13, color: accentColor),
                              const SizedBox(width: 3),
                              Text(ssid,
                                  style: const TextStyle(
                                      color: accentColor, fontSize: 13)),
                            ],
                          ],
                        )
                      : null,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DeviceSettingsScreen(),
                    ),
                  ),
                );
              },
            ),
            ValueListenableBuilder<String?>(
              valueListenable: _appState.serverHost,
              builder: (_, host, __) => _SettingsItem(
                icon: Icons.cloud_outlined,
                title: 'settings.remote'.tr(),
                subtitle: host,
                onTap: () async {
                  await showDialog(
                    context: context,
                    builder: (_) => const RemoteSettingsModal(),
                  );
                  setState(() {});
                },
              ),
            ),
            _SettingsItem(
              icon: Icons.language_outlined,
              title: 'settings.language'.tr(),
              subtitle: context.locale.languageCode == 'ko'
                  ? 'language.korean'.tr()
                  : 'language.english'.tr(),
              onTap: () => showDialog(
                context: context,
                builder: (_) => const LangSettingsModal(),
              ),
            ),
            _SettingsItem(
              icon: Icons.info_outline,
              title: 'settings.system_info'.tr(),
              onTap: () {},
            ),
            _SettingsItem(
              icon: Icons.system_update_alt_outlined,
              title: 'settings.firmware_update'.tr(),
              onTap: () {},
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
    this.subtitleWidget,
  });

  final String title;
  final IconData? icon;
  final String? subtitle;
  final Color? subtitleColor;
  final Widget? subtitleWidget;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget? sub;
    if (subtitleWidget != null) {
      sub = subtitleWidget;
    } else if (subtitle != null) {
      sub = Text(subtitle!,
          style: TextStyle(color: subtitleColor ?? Colors.white38, fontSize: 13));
    }

    return Column(
      children: [
        Divider(color: Colors.white.withValues(alpha: 0.1), height: 1, thickness: 1),
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: defaultPadding, vertical: 4),
          leading: icon != null
              ? Icon(icon, color: Colors.white70, size: 22)
              : null,
          title: Text(
            title,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          ),
          subtitle: sub,
          trailing: const Icon(Icons.chevron_right, color: Colors.white38),
          onTap: onTap,
        ),
      ],
    );
  }
}
