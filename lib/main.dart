import 'package:easy_localization/easy_localization.dart';
import 'package:nexiotcombo/constants.dart';
import 'package:nexiotcombo/screens/main/main_screen.dart';
import 'package:nexiotcombo/services/app_state.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Maps standard 2-letter locale codes to 3-letter filenames (eng.json, kor.json)
class _ThreeLetterAssetLoader extends RootBundleAssetLoader {
  const _ThreeLetterAssetLoader();

  static const _codeMap = {'en': 'eng', 'ko': 'kor'};

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) {
    final code = _codeMap[locale.languageCode] ?? locale.languageCode;
    return super.load(path, Locale(code));
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await AppState().loadSavedWifi();
  await AppState().loadSavedServer();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ko')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      assetLoader: const _ThreeLetterAssetLoader(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NexIoT',
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: bgColor,
        textTheme: GoogleFonts.notoSansKrTextTheme(Theme.of(context).textTheme)
            .apply(bodyColor: Colors.white),
        canvasColor: secondaryColor,
        scrollbarTheme: const ScrollbarThemeData(
          thumbVisibility: WidgetStatePropertyAll(false),
        ),
      ),
      home: MainScreen(),
    );
  }
}
