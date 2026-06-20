import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/custom_header.dart';
import '../widgets/custom_footer.dart';

/// Shared color tokens. Keeping these here (and mirrored in
/// upload_note_screen.dart) gives both screens the same identity:
/// warm paper background, indigo/violet primary, amber accent.
class _Palette {
  static const ink = Color(0xFF1A1F36);
  static const muted = Color(0xFF6B7280);
  static const paper = Color(0xFFF7F6F2);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFE7E5DE);
  static const indigo = Color(0xFF4F46E5);
  static const violet = Color(0xFF7C3AED);
  static const gold = Color(0xFFD97706);
  static const goldSoft = Color(0xFFFBF0DF);
  static const danger = Color(0xFFDC2626);
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String fullName = '';
  String email = '';
  String university = '';
  String department = '';
  String grade = '';
  String language = 'TR';
  bool isLoading = true;

  bool get isEnglish => language == 'EN';

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  String t(String tr, String en) => isEnglish ? en : tr;

  Future<void> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      fullName = prefs.getString('fullName') ?? '';
      email = prefs.getString('email') ?? '';
      university = prefs.getString('university') ?? '';
      department = prefs.getString('department') ?? '';
      grade = prefs.getString('grade') ?? '';
      language = prefs.getString('language') ?? 'TR';
      isLoading = false;
    });
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('language') ?? 'TR';

    await prefs.clear();
    await prefs.setString('language', savedLanguage);

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  // Every info row: icon + label + value as plain (non-selectable,
  // non-copyable) text.
  Widget buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    required bool isMobile,
  }) {
    final hasValue = value.isNotEmpty;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _Palette.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Palette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _Palette.goldSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _Palette.gold, size: 20),
          ),
          const SizedBox(width: 14),
          if (isMobile)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    title.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _Palette.muted,
                      fontSize: 11,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    hasValue ? value : '—',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _Palette.ink,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            SizedBox(
              width: 130,
              child: SelectableText(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _Palette.muted,
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              child: SelectableText(
                hasValue ? value : '—',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _Palette.ink,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBanner(bool isMobile, String initials) {
    final content = isMobile
        ? Column(
            children: [
              _Avatar(initials: initials, size: 74),
              const SizedBox(height: 16),
              SelectableText(
                t('Profilim', 'My Profile'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              SelectableText(
                t(
                  'Hesap bilgilerini buradan görüntüleyebilirsin.',
                  'You can view your account information here.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: Colors.white70,
                ),
              ),
            ],
          )
        : Row(
            children: [
              _Avatar(initials: initials, size: 76),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      t('Profilim', 'My Profile'),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      t(
                        'Hesap bilgilerini buradan görüntüleyebilirsin.',
                        'You can view your account information here.',
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 22 : 32,
        vertical: isMobile ? 28 : 34,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_Palette.indigo, _Palette.violet],
        ),
      ),
      child: content,
    );
  }

  // A row of small dots, colored to match the page background, sitting
  // right on the seam between the banner and the body — a student-ID /
  // ticket-stub perforation, the one deliberate flourish on this screen.
  Widget _buildPerforation() {
    return Container(
      width: double.infinity,
      height: 18,
      color: _Palette.card,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final count = (constraints.maxWidth / 16).floor().clamp(4, 200);
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              count,
              (i) => Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: _Palette.paper,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildProfileCard(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 650;
    final isTablet = width >= 650 && width < 1000;

    final initials = fullName.trim().isNotEmpty
        ? fullName
            .trim()
            .split(' ')
            .where((part) => part.isNotEmpty)
            .map((part) => part[0])
            .take(2)
            .join()
            .toUpperCase()
        : 'U';

    return Center(
      child: Container(
        width: isTablet ? 720 : 900,
        decoration: BoxDecoration(
          color: _Palette.card,
          borderRadius: BorderRadius.circular(isMobile ? 22 : 28),
          border: Border.all(color: _Palette.border),
          boxShadow: const [
            BoxShadow(
              color: Color.fromARGB(18, 0, 0, 0),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        // No SelectionArea here on purpose — profile fields shouldn't be
        // selectable or copyable.
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isMobile ? 22 : 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBanner(isMobile, initials),
              _buildPerforation(),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 22 : 34,
                  20,
                  isMobile ? 22 : 34,
                  isMobile ? 22 : 34,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    buildInfoRow(
                      icon: Icons.person_rounded,
                      title: t('Ad Soyad', 'Full Name'),
                      value: fullName,
                      isMobile: isMobile,
                    ),
                    buildInfoRow(
                      icon: Icons.email_rounded,
                      title: t('E-posta', 'Email'),
                      value: email,
                      isMobile: isMobile,
                    ),
                    buildInfoRow(
                      icon: Icons.account_balance_rounded,
                      title: t('Üniversite', 'University'),
                      value: university,
                      isMobile: isMobile,
                    ),
                    buildInfoRow(
                      icon: Icons.apartment_rounded,
                      title: t('Bölüm', 'Department'),
                      value: department,
                      isMobile: isMobile,
                    ),
                    buildInfoRow(
                      icon: Icons.workspace_premium_rounded,
                      title: t('Sınıf', 'Grade'),
                      value: grade,
                      isMobile: isMobile,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: isMobile ? double.infinity : null,
                      child: Align(
                        alignment:
                            isMobile ? Alignment.center : Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: logout,
                          icon: const Icon(Icons.logout_rounded),
                          label: Text(t('Çıkış Yap', 'Logout')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _Palette.danger,
                            side: const BorderSide(color: _Palette.danger),
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 24 : 24,
                              vertical: isMobile ? 17 : 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            minimumSize: isMobile
                                ? const Size(double.infinity, 0)
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 650;

    return Scaffold(
      backgroundColor: _Palette.paper,
      body: Column(
        children: [
          const CustomHeader(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 16 : 32,
                            vertical: isMobile ? 28 : 46,
                          ),
                          child: buildProfileCard(context),
                        ),
                        const CustomFooter(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  final double size;

  const _Avatar({
    required this.initials,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(size * 0.29),
        border: Border.all(color: Colors.white.withOpacity(0.55), width: 2),
      ),
      child: Center(
        child: SelectableText(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.37,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}