import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:nexiotcombo/constants.dart';

class LangSettingsModal extends StatefulWidget {
  const LangSettingsModal({super.key});

  @override
  State<LangSettingsModal> createState() => _LangSettingsModalState();
}

class _LangSettingsModalState extends State<LangSettingsModal> {
  String _tempLang = 'ko';
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final locale = EasyLocalization.of(context);
      if (locale != null) {
        _tempLang = locale.currentLocale?.languageCode ?? 'ko';
        _initialized = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: secondaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'language.title'.tr(),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LangOption(
            label: 'language.korean'.tr(),
            value: 'ko',
            groupValue: _tempLang,
            onChanged: (v) => setState(() => _tempLang = v!),
          ),
          _LangOption(
            label: 'language.english'.tr(),
            value: 'en',
            groupValue: _tempLang,
            onChanged: (v) => setState(() => _tempLang = v!),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('common.cancel'.tr(),
              style: const TextStyle(color: Colors.white54)),
        ),
        TextButton(
          onPressed: () {
            context.setLocale(Locale(_tempLang));
            Navigator.pop(context);
          },
          child: Text('common.ok'.tr(), style: TextStyle(color: primaryColor)),
        ),
      ],
    );
  }
}

class _LangOption extends StatelessWidget {
  const _LangOption({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String label, value, groupValue;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<String>(
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: primaryColor,
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
    );
  }
}
