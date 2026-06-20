import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kIndigo = Color(0xFF4F46E5);
const _kIndigoLight = Color(0xFFEEF0FF);
const _kSurface = Color(0xFFF9FAFB);
const _kBorder = Color(0xFFE5E7EB);
const _kTextPrimary = Color(0xFF111827);
const _kTextSecondary = Color(0xFF6B7280);

class CustomHeader extends StatefulWidget {
  const CustomHeader({super.key});

  @override
  State<CustomHeader> createState() => _CustomHeaderState();
}

class _CustomHeaderState extends State<CustomHeader> {
  bool isLoggedIn = false;
  String fullName = '';
  String language = 'TR';

  bool get isEnglish => language == 'EN';

  String t(String tr, String en) => isEnglish ? en : tr;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      fullName = prefs.getString('fullName') ?? '';
      language = prefs.getString('language') ?? 'TR';
    });
  }

  Future<void> _changeLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    setState(() => language = lang);
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      ModalRoute.of(context)?.settings.name ?? '/',
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('fullName');
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
  }

  void _goTo(String route) => Navigator.pushNamed(context, route);

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 980;
    final displayName = fullName.isNotEmpty ? fullName : t('Kullanıcı', 'User');

    return Container(
      height: isMobile ? 60 : 68,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: _kBorder, width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Logo(onTap: () => _goTo('/')),
          const Spacer(),
          if (!isMobile) ...[
            _NavLinks(
              currentRoute: ModalRoute.of(context)?.settings.name,
              isEnglish: isEnglish,
              onTap: _goTo,
            ),
            const SizedBox(width: 16),
          ],
          _LanguagePill(language: language, onChanged: _changeLanguage),
          const SizedBox(width: 12),
          if (!isMobile)
            _AccountArea(
              isLoggedIn: isLoggedIn,
              displayName: displayName,
              initials: _initials(displayName),
              t: t,
              onLogout: _logout,
              onNavigate: _goTo,
            )
          else
            _MobileMenu(
              isLoggedIn: isLoggedIn,
              isEnglish: isEnglish,
              t: t,
              onNavigate: _goTo,
              onLogout: _logout,
            ),
        ],
      ),
    );
  }
}

// ─── Logo ────────────────────────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  final VoidCallback onTap;
  const _Logo({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _kIndigo,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Uni Notes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _kTextPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Nav links (desktop) ─────────────────────────────────────────────────────

class _NavLinks extends StatelessWidget {
  final String? currentRoute;
  final bool isEnglish;
  final void Function(String route) onTap;

  const _NavLinks({
    required this.currentRoute,
    required this.isEnglish,
    required this.onTap,
  });

  String t(String tr, String en) => isEnglish ? en : tr;

  @override
  Widget build(BuildContext context) {
    final items = [
      (t('Ana Sayfa', 'Home'), '/'),
      (t('Dersler', 'Courses'), '/notes'),
      (t('Not Yükle', 'Upload Note'), '/upload'),
      (t('Derslerim', 'My Courses'), '/my-courses'),
      (t('Hakkında', 'About'), '/about'),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: items.map((e) {
        final isActive = currentRoute == e.$2;
        return _NavItem(
          title: e.$1,
          route: e.$2,
          isActive: isActive,
          onTap: () => onTap(e.$2),
        );
      }).toList(),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String title;
  final String route;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.title,
    required this.route,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? _kIndigoLight : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
            color: isActive ? _kIndigo : _kTextSecondary,
          ),
        ),
      ),
    );
  }
}

// ─── Language pill ────────────────────────────────────────────────────────────

class _LanguagePill extends StatelessWidget {
  final String language;
  final Future<void> Function(String) onChanged;

  const _LanguagePill({required this.language, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _kBorder, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['TR', 'EN'].map((code) {
          final selected = language == code;
          return GestureDetector(
            onTap: selected ? null : () => onChanged(code),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                border: selected
                    ? Border.all(color: _kBorder, width: 0.5)
                    : null,
              ),
              child: Text(
                code,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? _kIndigo : _kTextSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Account area (desktop) ───────────────────────────────────────────────────

class _AccountArea extends StatelessWidget {
  final bool isLoggedIn;
  final String displayName;
  final String initials;
  final String Function(String, String) t;
  final Future<void> Function() onLogout;
  final void Function(String) onNavigate;

  const _AccountArea({
    required this.isLoggedIn,
    required this.displayName,
    required this.initials,
    required this.t,
    required this.onLogout,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn) {
      return _PrimaryButton(
        icon: Icons.login_rounded,
        label: t('Giriş Yap', 'Login'),
        onTap: () => onNavigate('/login'),
      );
    }

    return PopupMenuButton<String>(
      offset: const Offset(0, 46),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 180),
      onSelected: (v) {
        if (v == 'logout') {
          onLogout();
        } else {
          onNavigate(v);
        }
      },
      itemBuilder: (_) => [
        _menuItem('/profile', Icons.person_rounded, t('Profil', 'Profile')),
        _menuItem(
            '/upload', Icons.upload_file_rounded, t('Not Yükle', 'Upload Note')),
        const PopupMenuDivider(height: 1),
        _menuItem('logout', Icons.logout_rounded, t('Çıkış Yap', 'Logout'),
            color: Colors.red.shade600),
      ],
      child: _AvatarButton(initials: initials, name: displayName),
    );
  }
}

PopupMenuItem<String> _menuItem(
  String value,
  IconData icon,
  String label, {
  Color? color,
}) {
  final c = color ?? _kTextPrimary;
  return PopupMenuItem<String>(
    value: value,
    height: 40,
    child: Row(
      children: [
        Icon(icon, size: 18, color: c),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: c,
          ),
        ),
      ],
    ),
  );
}

class _AvatarButton extends StatelessWidget {
  final String initials;
  final String name;

  const _AvatarButton({required this.initials, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _kIndigoLight,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _kIndigo,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _kTextPrimary,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down_rounded,
              size: 16, color: _kTextSecondary),
        ],
      ),
    );
  }
}

// ─── Mobile hamburger menu ────────────────────────────────────────────────────

class _MobileMenu extends StatelessWidget {
  final bool isLoggedIn;
  final bool isEnglish;
  final String Function(String, String) t;
  final void Function(String) onNavigate;
  final Future<void> Function() onLogout;

  const _MobileMenu({
    required this.isLoggedIn,
    required this.isEnglish,
    required this.t,
    required this.onNavigate,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: t('Menü', 'Menu'),
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (v) {
        if (v == 'logout') {
          onLogout();
        } else {
          onNavigate(v);
        }
      },
      itemBuilder: (_) => [
        _menuItem('/', Icons.home_rounded, t('Ana Sayfa', 'Home')),
        _menuItem('/notes', Icons.menu_book_rounded, t('Dersler', 'Courses')),
        _menuItem('/upload', Icons.upload_file_rounded, t('Not Yükle', 'Upload Note')),
        _menuItem('/my-courses', Icons.bookmark_added_rounded, t('Derslerim', 'My Courses')),
        _menuItem('/about', Icons.info_outline_rounded, t('Hakkında', 'About')),
        const PopupMenuDivider(height: 1),
        if (isLoggedIn) ...[
          _menuItem('/profile', Icons.person_rounded, t('Profil', 'Profile')),
          _menuItem('logout', Icons.logout_rounded, t('Çıkış Yap', 'Logout'),
              color: Colors.red.shade600),
        ] else
          _menuItem('/login', Icons.login_rounded, t('Giriş Yap', 'Login')),
      ],
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBorder, width: 0.5),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.menu_rounded,
            size: 18, color: _kTextPrimary),
      ),
    );
  }
}

// ─── Primary button ───────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: _kIndigo,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}