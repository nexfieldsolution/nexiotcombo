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
          DrawerListTile(
            title: 'menu.devices'.tr(),
            svgSrc: "assets/icons/menu_dashboard.svg",
            press: () {
              Navigator.pop(context);
              onSectionChanged?.call(AppSection.summary);
            },
          ),
          DrawerListTile(
            title: 'menu.monitoring'.tr(),
            svgSrc: "assets/icons/menu_task.svg",
            press: () {
              Navigator.pop(context);
              onSectionChanged?.call(AppSection.monitoring);
            },
          ),
          DrawerListTile(
            title: 'menu.events'.tr(),
            svgSrc: "assets/icons/menu_notification.svg",
            press: () {},
          ),
          DrawerListTile(
            title: 'menu.history'.tr(),
            svgSrc: "assets/icons/menu_doc.svg",
            press: () {},
          ),
          DrawerListTile(
            title: 'menu.login'.tr(),
            svgSrc: "assets/icons/menu_profile.svg",
            press: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
          const Divider(color: Colors.white12, height: 1),
          DrawerListTile(
            title: 'menu.settings'.tr(),
            svgSrc: "assets/icons/menu_setting.svg",
            press: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class DrawerListTile extends StatelessWidget {
  const DrawerListTile({
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
        style: TextStyle(color: iconColor, fontWeight: FontWeight.bold),
      ),
    );
  }
}
