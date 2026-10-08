import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nexiotcombo/constants.dart';
import 'package:nexiotcombo/screens/login/login_screen.dart';
import 'package:nexiotcombo/screens/settings/settings_screen.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({
    Key? key,
    this.onSectionChanged,
  }) : super(key: key);

  final ValueChanged<AppSection>? onSectionChanged;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.7,
      backgroundColor: bgColor,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(color: Colors.transparent),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new,
                              color: Colors.white, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      Center(
                        child: Transform.translate(
                          offset: const Offset(-23, 0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset("assets/images/logo.png",
                                  width: 36, height: 36),
                              const SizedBox(width: 10),
                              Text.rich(
                                TextSpan(children: [
                                  TextSpan(text: 'NEX',
                                      style: const TextStyle(color: accentBlueColor)),
                                  TextSpan(text: 'IOT',
                                      style: const TextStyle(color: Colors.orange)),
                                ]),
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SideMenuItem(
                  title: 'menu.devices'.tr(),
                  svgSrc: "assets/icons/menu_summary.svg",
                  iconColor: const Color(0xFF4FC3F7),
                  press: () {
                    Navigator.pop(context);
                    onSectionChanged?.call(AppSection.summary);
                  },
                ),
                SideMenuItem(
                  title: 'menu.monitoring'.tr(),
                  svgSrc: "assets/icons/menu_monitoring.svg",
                  iconColor: const Color(0xFF00C897),
                  press: () {
                    Navigator.pop(context);
                    onSectionChanged?.call(AppSection.monitoring);
                  },
                ),
                SideMenuItem(
                  title: 'menu.events'.tr(),
                  svgSrc: "assets/icons/menu_events.svg",
                  iconColor: const Color(0xFFFFB800),
                  press: () {},
                ),
                SideMenuItem(
                  title: 'menu.history'.tr(),
                  svgSrc: "assets/icons/menu_history.svg",
                  iconColor: const Color(0xFFFF8A65),
                  press: () {},
                ),
                const Divider(color: Colors.white12, height: 1),
                SideMenuItem(
                  title: 'menu.settings'.tr(),
                  svgSrc: "assets/icons/menu_settings.svg",
                  iconColor: const Color(0xFFBA68C8),
                  press: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
                SideMenuItem(
                  title: 'menu.login'.tr(),
                  svgSrc: "assets/icons/menu_login.svg",
                  iconColor: const Color(0xFFF06292),
                  press: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
         // const Divider(color: Colors.white12, height: 1),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 12, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(children: [
                    const TextSpan(
                      text: 'NEXIOT',
                      style: TextStyle(color: darkBlueColor, fontSize: 11),
                    ),
                    TextSpan(
                      text: ' ${'login.footer_company'.tr()}',
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ]),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.email_outlined, color: Colors.white38, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      'login.footer_contact'.tr(),
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SideMenuItem extends StatelessWidget {
  const SideMenuItem({
    Key? key,
    required this.title,
    required this.svgSrc,
    required this.press,
    this.iconColor = Colors.white,
  }) : super(key: key);

  final String title, svgSrc;
  final VoidCallback press;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: press,
      horizontalTitleGap: 0.0,
      leading: ColorFiltered(
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        child: SvgPicture.asset(svgSrc, height: 16),
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
