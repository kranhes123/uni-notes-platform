import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomFooter extends StatefulWidget {
  const CustomFooter({super.key});

  @override
  State<CustomFooter> createState() => _CustomFooterState();
}

class _CustomFooterState extends State<CustomFooter> {
  String language = 'TR';

  bool get isEnglish => language == 'EN';

  String t(String tr, String en) => isEnglish ? en : tr;

  @override
  void initState() {
    super.initState();
    loadLanguage();
  }

  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      language = prefs.getString('language') ?? 'TR';
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobileOrTablet = width < 900;

    final links = [
      _FooterLinkData(
        text: t('Ana Sayfa', 'Home'),
        route: '/',
        icon: Icons.home_rounded,
      ),
      _FooterLinkData(
        text: t('Notlar', 'Notes'),
        route: '/notes',
        icon: Icons.menu_book_rounded,
      ),
      _FooterLinkData(
        text: t('Not Yükle', 'Upload Note'),
        route: '/upload',
        icon: Icons.upload_file_rounded,
      ),
      _FooterLinkData(
        text: t('Hakkında', 'About'),
        route: '/about',
        icon: Icons.info_rounded,
      ),
      _FooterLinkData(
        text: t('Giriş Yap', 'Login'),
        route: '/login',
        icon: Icons.login_rounded,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobileOrTablet ? 20 : 32,
        vertical: isMobileOrTablet ? 24 : 22,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            children: [
              if (isMobileOrTablet)
                Column(
                  children: links
                      .map(
                        (item) => _FooterMobileLink(
                          icon: item.icon,
                          text: item.text,
                          onTap: () => Navigator.pushNamed(context, item.route),
                        ),
                      )
                      .toList(),
                )
              else
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 26,
                  runSpacing: 12,
                  children: links
                      .map(
                        (item) => _FooterDesktopLink(
                          text: item.text,
                          onTap: () => Navigator.pushNamed(context, item.route),
                        ),
                      )
                      .toList(),
                ),

              SizedBox(height: isMobileOrTablet ? 22 : 18),

              Container(
                width: isMobileOrTablet ? 80 : 100,
                height: 1,
                color: const Color(0xFFE5E7EB),
              ),

              SizedBox(height: isMobileOrTablet ? 18 : 16),

              Text(
                '© 2026 Uni Notes Platform',
                style: TextStyle(
                  fontSize: isMobileOrTablet ? 13 : 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 5),

              Text(
                isEnglish ? 'Graduation Project' : 'Bitirme Projesi',
                style: TextStyle(
                  fontSize: isMobileOrTablet ? 12 : 13,
                  color: const Color(0xFF9CA3AF),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterLinkData {
  final String text;
  final String route;
  final IconData icon;

  const _FooterLinkData({
    required this.text,
    required this.route,
    required this.icon,
  });
}

class _FooterDesktopLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _FooterDesktopLink({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 4,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
      ),
    );
  }
}

class _FooterMobileLink extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _FooterMobileLink({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: const Color(0xFF4F46E5),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}