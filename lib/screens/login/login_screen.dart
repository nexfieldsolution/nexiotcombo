import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:nexiotcombo/constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _showEmailForm = false;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top -
                MediaQuery.of(context).padding.bottom,
          ),
          child: IntrinsicHeight(
            child: Column(
              children: [
                // ── 헤더 ─────────────────────────────────────────
                Container(
                  width: double.infinity,
                  color: secondaryColor,
                  padding: const EdgeInsets.symmetric(
                      horizontal: defaultPadding, vertical: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Image.asset("assets/images/logo.png",
                              width: 36, height: 36),
                          const SizedBox(width: 10),
                          const Text(
                            "NEXIOT",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Image.asset(
                              'assets/icons/ic_nav_back.png',
                              width: 32,
                              height: 32,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'login.title'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'login.subtitle'.tr(),
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13),
                      ),
                    ],
                  ),
                ),

                // ── 콘텐츠 영역 (소셜 버튼 ↔ 이메일 폼) ─────────────
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: defaultPadding),
                  child: FractionallySizedBox(
                    widthFactor: 0.9,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _showEmailForm
                          ? _buildEmailForm()
                          : _buildSocialButtons(),
                    ),
                  ),
                ),

                const Spacer(),

                // ── 푸터 ─────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: defaultPadding, vertical: 20),
                  decoration: BoxDecoration(
                    border: Border(
                        top: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08))),
                  ),
                  child: Column(
                    children: [
                      RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                          style: TextStyle(fontSize: 12),
                          children: [
                            TextSpan(
                              text: 'NEXIOT',
                              style: TextStyle(
                                color: darkBlueColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: ' · 넥스필드솔루션',
                              style: TextStyle(color: Colors.white38),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'login.footer_contact'.tr(),
                        style: const TextStyle(
                            color: Colors.white24, fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButtons() {
    return Column(
      key: const ValueKey('social'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(
          'login.social_title'.tr(),
          style: const TextStyle(color: Colors.white54, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        _SocialButton(
          label: 'Naver',
          icon: const Text('N',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          bgColor: const Color(0xFF03C75A),
          textColor: Colors.white,
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _SocialButton(
          label: 'Kakao',
          icon: Image.asset('assets/icons/social_kakao.png',
              width: 24, height: 24),
          bgColor: const Color(0xFFFEE500),
          textColor: const Color(0xFF3C1E1E),
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _SocialButton(
          label: 'Gmail',
          icon: Image.asset('assets/icons/social_google.png',
              width: 24, height: 24),
          bgColor: Colors.white,
          textColor: const Color(0xFF3C4043),
          onTap: () {},
        ),
        const SizedBox(height: 24),
        const Divider(color: Colors.white12),
        const SizedBox(height: 12),
        _SocialButton(
          label: 'login.btn_email'.tr(),
          icon: const Icon(Icons.person_outline, color: Colors.white, size: 22),
          bgColor: accentBlueColor,
          textColor: Colors.white,
          addSuffix: false,
          onTap: () => setState(() => _showEmailForm = true),
        ),
      ],
    );
  }

  Widget _buildEmailForm() {
    return Column(
      key: const ValueKey('email'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('login.btn_email'.tr(),
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _showEmailForm = false),
              child: Image.asset('assets/icons/ic_nav_back.png',
                  width: 28, height: 28),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _fieldLabel('login.email'.tr()),
        const SizedBox(height: 6),
        _textField(
          controller: _emailCtrl,
          hint: 'login.email_hint'.tr(),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _fieldLabel('login.password'.tr()),
        const SizedBox(height: 6),
        _textField(
          controller: _passwordCtrl,
          hint: 'login.password_hint'.tr(),
          obscure: _obscure,
          suffix: IconButton(
            icon: Icon(
              _obscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.white38,
              size: 20,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentBlueColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {},
            child: Text('login.btn_login'.tr(),
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('login.no_account'.tr(),
                  style:
                      const TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {},
                child: Text('login.btn_signup'.tr(),
                    style: const TextStyle(
                        color: accentColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(
            color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
      );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffix,
  }) =>
      TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
          filled: true,
          fillColor: secondaryColor,
          suffixIcon: suffix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: accentColor),
          ),
        ),
      );
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.textColor,
    required this.onTap,
    this.addSuffix = true,
  });

  final String label;
  final Widget icon;
  final Color bgColor;
  final Color textColor;
  final VoidCallback onTap;
  final bool addSuffix;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 24, height: 24, child: Center(child: icon)),
            const SizedBox(width: 12),
            Text(
              addSuffix ? '$label 로 로그인' : label,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}
