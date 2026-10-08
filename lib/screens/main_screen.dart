import 'package:easy_localization/easy_localization.dart';
import 'package:nexiotcombo/constants.dart';
import 'package:nexiotcombo/components/device_detail_content.dart';
import 'package:nexiotcombo/components/responsive.dart';
import 'package:nexiotcombo/components/side_menu.dart';
import 'package:nexiotcombo/screens/monitoring/monitoring_screen.dart';
import 'package:nexiotcombo/screens/summary/summary_screen.dart';
import 'package:nexiotcombo/services/app_state.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  AppSection _section = AppSection.summary;
  String? _selectedDeviceId;

  Future<bool> _onExit(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: secondaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          'app.exit_confirm'.tr(),
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('common.cancel'.tr(),
                style: const TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('common.ok'.tr(),
                style: const TextStyle(color: accentBlueColor)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_selectedDeviceId != null) {
          setState(() => _selectedDeviceId = null);
          return;
        }
        if (_section == AppSection.monitoring) {
          setState(() => _section = AppSection.summary);
          return;
        }
        final exit = await _onExit(context);
        if (exit && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        drawer: SideMenu(
          onSectionChanged: (section) {
            setState(() {
              _section = section;
              _selectedDeviceId = null;
            });
          },
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildCommonHeader(context),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (Responsive.isDesktop(context))
                      Expanded(
                        child: SideMenu(
                          onSectionChanged: (section) {
                            setState(() {
                              _section = section;
                              _selectedDeviceId = null;
                            });
                          },
                        ),
                      ),
                    Expanded(
                      flex: 5,
                      child: _buildContent(),
                    ),
                  ],
                ),
              ),
            //  _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_selectedDeviceId != null) {
      return DeviceDetailContent(
        deviceId: _selectedDeviceId!,
        onClose: () => setState(() => _selectedDeviceId = null),
      );
    }
    if (_section == AppSection.monitoring) {
      return MonitoringScreen(
        onDeviceSelected: (id) => setState(() => _selectedDeviceId = id),
      );
    }
    return const SummaryScreen();
  }

  Widget _buildCommonHeader(BuildContext context) {
    return Container(
      color: secondaryColor,
      padding: const EdgeInsets.only(
          left: defaultPadding, right: defaultPadding + 8, top: 16, bottom: 16),
      child: Row(
        children: [
          Builder(
            builder: (ctx) => GestureDetector(
              onTap: () => Scaffold.of(ctx).openDrawer(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
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
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildConnectionStatus(),
              const SizedBox(height: 2),
              Text(
                'summary.subtitle'.tr(),
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
          const Spacer(),
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white, size: 26),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    final appState = AppState();
    return ListenableBuilder(
      listenable: Listenable.merge(
          [appState.btDevice, appState.serverHost]),
      builder: (_, __) {
        final btConnected = appState.btDevice.value != null;
        final serverConnected = appState.serverHost.value != null;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bluetooth,
              size: 13,
              color: btConnected ? accentBlueColor : Colors.white24,
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.cloud_outlined,
              size: 13,
              color: serverConnected ? const Color(0xFF00C897) : Colors.white24,
            ),
          ],
        );
      },
    );
  }

  // ── 바텀바 (추후 메뉴 버튼 추가 예정) ──────────────────
  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: secondaryColor,
        border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      // TODO: BottomNavigationBar 버튼 추가
    );
  }
}
