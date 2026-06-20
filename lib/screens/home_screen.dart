import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/custom_header.dart';
import '../widgets/custom_footer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String language = 'TR';
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  bool get isEnglish => language == 'EN';

  // Maksimum içerik genişliği — ekran bundan büyükse içerik ortalanır,
  // küçükse mevcut genişliğe (padding düşülmüş) sığar.
  static const double maxContentWidth = 1180;

  @override
  void initState() {
    super.initState();
    loadLanguage();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      language = prefs.getString('language') ?? 'TR';
    });
  }

  String t(String tr, String en) => isEnglish ? en : tr;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;
    final isTablet = width >= 700 && width < 1050;
    final isSmall = width < 1050;

    // Gerçek içerik genişliği: ekran genişliği - yatay padding, ama
    // maxContentWidth'i hiçbir zaman aşmaz. Feature card genişlik
    // hesaplarında bunu kullanıyoruz ki taşma olmasın.
    final horizontalPadding = isMobile ? 20.0 : 48.0;
    final contentWidth =
        (width - horizontalPadding * 2).clamp(0.0, maxContentWidth);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2FA),
      // Tüm sayfadaki metinler (başlıklar, açıklamalar, kartlar vb.)
      // SelectionArea sayesinde seçilebilir/kopyalanabilir hale gelir.
      body: SelectionArea(
        child: Column(
          children: [
            const CustomHeader(),
            Expanded(
              child: FadeTransition(
                opacity: _fadeIn,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // ── HERO ──────────────────────────────────────────────
                      Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF0F0C29), Color(0xFF302B63)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: isMobile ? 48 : 80,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: maxContentWidth,
                              ),
                              child: isSmall
                                  ? Column(
                                      children: [
                                        _HeroText(isMobile: isMobile, t: t),
                                        SizedBox(height: isMobile ? 36 : 48),
                                        _HeroFloatingCards(
                                            isMobile: isMobile, t: t),
                                      ],
                                    )
                                  : Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          flex: 55,
                                          child: _HeroText(
                                              isMobile: false, t: t),
                                        ),
                                        const SizedBox(width: 60),
                                        Expanded(
                                          flex: 45,
                                          child: _HeroFloatingCards(
                                              isMobile: false, t: t),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),

                      // ── STATS STRIP ───────────────────────────────────────
                      Container(
                        color: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: isMobile ? 20 : 28,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: maxContentWidth,
                            ),
                            child: isMobile
                                ? Column(
                                    children: [
                                      _StatStrip(
                                        value: t('Akıllı', 'Smart'),
                                        label: t(
                                            'Benzer not tespiti',
                                            'Similarity detection'),
                                        icon: Icons.auto_awesome_rounded,
                                      ),
                                      const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 10),
                                        child: Divider(),
                                      ),
                                      _StatStrip(
                                        value: t('Hızlı', 'Fast'),
                                        label: t(
                                            'Filtrelenmiş arama',
                                            'Filtered search'),
                                        icon: Icons.bolt_rounded,
                                      ),
                                      const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 10),
                                        child: Divider(),
                                      ),
                                      _StatStrip(
                                        value: t('Düzenli', 'Organized'),
                                        label: t(
                                            'Ders arşivi',
                                            'Course archive'),
                                        icon: Icons.folder_copy_rounded,
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _StatStrip(
                                        value: t('Akıllı', 'Smart'),
                                        label: t(
                                            'Benzer not tespiti',
                                            'Similarity detection'),
                                        icon: Icons.auto_awesome_rounded,
                                      ),
                                      Container(
                                          height: 48,
                                          width: 1,
                                          color: const Color(0xFFE5E7EB)),
                                      _StatStrip(
                                        value: t('Hızlı', 'Fast'),
                                        label: t(
                                            'Filtrelenmiş arama',
                                            'Filtered search'),
                                        icon: Icons.bolt_rounded,
                                      ),
                                      Container(
                                          height: 48,
                                          width: 1,
                                          color: const Color(0xFFE5E7EB)),
                                      _StatStrip(
                                        value: t('Düzenli', 'Organized'),
                                        label: t(
                                            'Ders arşivi',
                                            'Course archive'),
                                        icon: Icons.folder_copy_rounded,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),

                      // ── FEATURES ─────────────────────────────────────────
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: isMobile ? 40 : 64,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: maxContentWidth,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SectionLabel(
                                    text: t('Özellikler', 'Features')),
                                const SizedBox(height: 10),
                                Text(
                                  t(
                                    'Neden Uni Notes?',
                                    'Why Uni Notes?',
                                  ),
                                  style: TextStyle(
                                    fontSize: isMobile ? 26 : 34,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F0C29),
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  t(
                                    'Öğrenci deneyimini merkeze alan, yapay zeka destekli not paylaşım platformu.',
                                    'An AI-powered note-sharing platform built around the student experience.',
                                  ),
                                  style: TextStyle(
                                    fontSize: isMobile ? 15 : 17,
                                    color: const Color(0xFF6B7280),
                                    height: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 36),
                                Wrap(
                                  spacing: 20,
                                  runSpacing: 20,
                                  children: [
                                    _FeatureCard(
                                      width: isMobile
                                          ? double.infinity
                                          : isTablet
                                              ? (contentWidth - 20) / 2
                                              : (contentWidth - 40) / 3,
                                      icon: Icons.upload_file_rounded,
                                      accent: const Color(0xFF6C63FF),
                                      title: t(
                                          'Kolay Yükleme', 'Easy Upload'),
                                      description: t(
                                        'PDF veya DOCX notlarınızı saniyeler içinde platforma ekleyin.',
                                        'Add your PDF or DOCX notes to the platform in seconds.',
                                      ),
                                    ),
                                    _FeatureCard(
                                      width: isMobile
                                          ? double.infinity
                                          : isTablet
                                              ? (contentWidth - 20) / 2
                                              : (contentWidth - 40) / 3,
                                      icon: Icons.manage_search_rounded,
                                      accent: const Color(0xFF10B981),
                                      title: t(
                                          'Akıllı Filtreleme',
                                          'Smart Filtering'),
                                      description: t(
                                        'Üniversite, bölüm, sınıf ve derse göre anında filtreleyin.',
                                        'Filter instantly by university, department, grade and course.',
                                      ),
                                    ),
                                    _FeatureCard(
                                      width: isMobile
                                          ? double.infinity
                                          : isTablet
                                              ? (contentWidth - 20) / 2
                                              : (contentWidth - 40) / 3,
                                      icon: Icons.psychology_alt_rounded,
                                      accent: const Color(0xFFF59E0B),
                                      title: t(
                                          'Yapay Zeka Analizi',
                                          'AI Analysis'),
                                      description: t(
                                        'İçerikler analiz edilerek benzer notlar otomatik tespit edilir.',
                                        'Content is analyzed to automatically detect similar notes.',
                                      ),
                                    ),
                                    _FeatureCard(
                                      width: isMobile
                                          ? double.infinity
                                          : isTablet
                                              ? (contentWidth - 20) / 2
                                              : (contentWidth - 40) / 3,
                                      icon: Icons.download_rounded,
                                      accent: const Color(0xFFEF4444),
                                      title: t(
                                          'Anında Erişim', 'Instant Access'),
                                      description: t(
                                        'İhtiyacınız olan notlara tek tıkla ulaşın, indirin.',
                                        'Reach and download the notes you need with one click.',
                                      ),
                                    ),
                                    _FeatureCard(
                                      width: isMobile
                                          ? double.infinity
                                          : isTablet
                                              ? (contentWidth - 20) / 2
                                              : (contentWidth - 40) / 3,
                                      icon: Icons.bookmark_added_rounded,
                                      accent: const Color(0xFF8B5CF6),
                                      title: t('Derslerim', 'My Courses'),
                                      description: t(
                                        'Takip ettiğiniz dersleri kişisel listenize ekleyin.',
                                        'Add courses you follow to your personal list.',
                                      ),
                                    ),
                                    _FeatureCard(
                                      width: isMobile
                                          ? double.infinity
                                          : isTablet
                                              ? (contentWidth - 20) / 2
                                              : (contentWidth - 40) / 3,
                                      icon: Icons.groups_rounded,
                                      accent: const Color(0xFF06B6D4),
                                      title: t(
                                          'Topluluk Gücü',
                                          'Community Power'),
                                      description: t(
                                        'Öğrenciler birbirine destek olarak birlikte başarır.',
                                        'Students succeed together by supporting each other.',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // ── CTA BANNER ───────────────────────────────────────
                      Padding(
                        padding: EdgeInsets.only(
                          left: horizontalPadding,
                          right: horizontalPadding,
                          bottom: isMobile ? 40 : 64,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: maxContentWidth,
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 28 : 56,
                                vertical: isMobile ? 36 : 52,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6C63FF),
                                    Color(0xFF302B63),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(
                                    isMobile ? 24 : 32),
                              ),
                              child: isSmall
                                  ? Column(
                                      children: [
                                        _CtaContent(
                                            isMobile: isMobile, t: t),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: _CtaContent(
                                              isMobile: false, t: t),
                                        ),
                                        const SizedBox(width: 32),
                                        _CtaButtons(
                                            isMobile: false, t: t),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),

                      const CustomFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── HERO TEXT ────────────────────────────────────────────────────────────────
class _HeroText extends StatelessWidget {
  final bool isMobile;
  final String Function(String, String) t;
  const _HeroText({required this.isMobile, required this.t});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isMobile
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(0.22)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: Color(0xFFFFD700), size: 15),
              const SizedBox(width: 6),
              Text(
                t('Akıllı Not Platformu', 'Smart Note Platform'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          t(
            'Ders notlarına\nakıllıca eriş.',
            'Access lecture notes\nsmarter.',
          ),
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: isMobile ? 36 : 58,
            height: 1.1,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          t(
            'Uni Notes ile notlarını paylaş, ara, filtrele ve yapay zeka destekli benzerlik analizi ile kaynakları doğrula.',
            'Share, search, filter your notes and verify resources with AI-powered similarity analysis using Uni Notes.',
          ),
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: isMobile ? 15 : 17,
            height: 1.7,
            color: Colors.white.withOpacity(0.75),
          ),
        ),
        const SizedBox(height: 36),
        Wrap(
          alignment:
              isMobile ? WrapAlignment.center : WrapAlignment.start,
          spacing: 14,
          runSpacing: 14,
          children: [
            _HeroBtn(
              label: t('Not Yükle', 'Upload Notes'),
              icon: Icons.upload_file_rounded,
              filled: true,
              onTap: () => Navigator.pushNamed(context, '/upload'),
            ),
            _HeroBtn(
              label: t('Notları Keşfet', 'Explore Notes'),
              icon: Icons.search_rounded,
              filled: false,
              onTap: () => Navigator.pushNamed(context, '/notes'),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;
  const _HeroBtn(
      {required this.label,
      required this.icon,
      required this.filled,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        decoration: BoxDecoration(
          color: filled
              ? const Color(0xFF6C63FF)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: filled
                ? const Color(0xFF6C63FF)
                : Colors.white.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── HERO FLOATING CARDS ──────────────────────────────────────────────────────
class _HeroFloatingCards extends StatelessWidget {
  final bool isMobile;
  final String Function(String, String) t;
  const _HeroFloatingCards(
      {required this.isMobile, required this.t});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FloatCard(
          icon: Icons.folder_copy_rounded,
          iconColor: const Color(0xFF6C63FF),
          bg: const Color(0xFF1E1B4B),
          title: t('Ders Arşivi', 'Course Archive'),
          subtitle: t(
            'Tüm dersler düzenli ve erişilebilir',
            'All courses organized and accessible',
          ),
        ),
        const SizedBox(height: 14),
        _FloatCard(
          icon: Icons.psychology_alt_rounded,
          iconColor: const Color(0xFF10B981),
          bg: const Color(0xFF1A2E26),
          title: t('Benzerlik Analizi', 'Similarity Analysis'),
          subtitle: t(
            '%80+ eşleşme otomatik uyarı',
            '80%+ match triggers auto-warning',
          ),
        ),
        const SizedBox(height: 14),
        _FloatCard(
          icon: Icons.bolt_rounded,
          iconColor: const Color(0xFFFBBF24),
          bg: const Color(0xFF2D2314),
          title: t('Anlık Arama', 'Instant Search'),
          subtitle: t(
            'Bölüm, dönem, ders bazlı filtre',
            'Filter by department, semester, course',
          ),
        ),
      ],
    );
  }
}

class _FloatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bg;
  final String title;
  final String subtitle;
  const _FloatCard({
    required this.icon,
    required this.iconColor,
    required this.bg,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    )),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 13,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── STAT STRIP ───────────────────────────────────────────────────────────────
class _StatStrip extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _StatStrip(
      {required this.value,
      required this.label,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF6C63FF), size: 22),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F0C29),
                )),
            Text(label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                )),
          ],
        ),
      ],
    );
  }
}

// ── SECTION LABEL ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF6C63FF),
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

// ── FEATURE CARD ─────────────────────────────────────────────────────────────
class _FeatureCard extends StatefulWidget {
  final double width;
  final IconData icon;
  final Color accent;
  final String title;
  final String description;

  const _FeatureCard({
    required this.width,
    required this.icon,
    required this.accent,
    required this.title,
    required this.description,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: widget.width,
        constraints: const BoxConstraints(minHeight: 210),
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _hovered
                ? widget.accent.withOpacity(0.4)
                : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? widget.accent.withOpacity(0.12)
                  : Colors.black.withOpacity(0.05),
              blurRadius: _hovered ? 24 : 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: widget.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(widget.icon, size: 26, color: widget.accent),
            ),
            const SizedBox(height: 20),
            Text(widget.title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                )),
            const SizedBox(height: 10),
            Text(widget.description,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.55,
                  color: Color(0xFF6B7280),
                )),
          ],
        ),
      ),
    );
  }
}

// ── CTA BANNER ───────────────────────────────────────────────────────────────
class _CtaContent extends StatelessWidget {
  final bool isMobile;
  final String Function(String, String) t;
  const _CtaContent({required this.isMobile, required this.t});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isMobile
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          t(
            'Hemen başla, notlarını paylaş.',
            'Get started, share your notes.',
          ),
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: isMobile ? 22 : 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          t(
            'Binlerce öğrenciye katkı sağla, akademik topluluğun parçası ol.',
            'Contribute to thousands of students, be part of the academic community.',
          ),
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: 15,
            color: Colors.white.withOpacity(0.7),
            height: 1.5,
          ),
        ),
        if (isMobile) ...[
          const SizedBox(height: 24),
          _CtaButtons(isMobile: true, t: t),
        ],
      ],
    );
  }
}

class _CtaButtons extends StatelessWidget {
  final bool isMobile;
  final String Function(String, String) t;
  const _CtaButtons({required this.isMobile, required this.t});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/upload'),
          icon: const Icon(Icons.upload_file_rounded, size: 18),
          label: Text(t('Not Yükle', 'Upload')),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF302B63),
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 0,
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/notes'),
          icon: const Icon(Icons.search_rounded, size: 18),
          label: Text(t('Keşfet', 'Explore')),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.white.withOpacity(0.5)),
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}