import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/custom_header.dart';
import '../widgets/custom_footer.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String language = 'TR';
  bool get isEnglish => language == 'EN';

  // Contact form controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  bool _formSent = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    loadLanguage();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      language = prefs.getString('language') ?? 'TR';
    });
  }

  String t(String tr, String en) => isEnglish ? en : tr;

  Future<void> _sendForm() async {
  if (_nameController.text.trim().isEmpty ||
      _messageController.text.trim().isEmpty) return;

  setState(() => _sending = true);

  try {
    final response = await http.post(
      Uri.parse('https://uni-notes-platform-production.up.railway.app/contact'), // canlıya alınca backend URL'in ile değiştir
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'message': _messageController.text.trim(),
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        _sending = false;
        _formSent = true;
      });
    } else {
      setState(() => _sending = false);
      // İstersen burada bir hata snackbar'ı gösterebilirsin
      debugPrint('Mail gönderilemedi: ${response.body}');
    }
  } catch (e) {
    setState(() => _sending = false);
    debugPrint('Mail gönderim hatası: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 650;
    final isTablet = width >= 650 && width < 1050;
    final isSmall = width < 1050;

    return SelectionArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F2FA),
        body: Column(
          children: [
            const CustomHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // ── HERO ────────────────────────────────────────────────
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF0D1117),
                            Color(0xFF161B2E),
                            Color(0xFF1A1040),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 20 : 48,
                          vertical: isMobile ? 52 : 88,
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 1180,
                            child: isSmall
                                ? Column(
                                    children: [
                                      _AboutHeroText(
                                          isMobile: isMobile, t: t),
                                      SizedBox(
                                          height: isMobile ? 36 : 48),
                                      _AboutHeroVisual(isMobile: isMobile),
                                    ],
                                  )
                                : Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        flex: 6,
                                        child: _AboutHeroText(
                                            isMobile: false, t: t),
                                      ),
                                      const SizedBox(width: 60),
                                      Expanded(
                                        flex: 4,
                                        child: _AboutHeroVisual(
                                            isMobile: false),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),

                    // ── MISSION STATEMENT ────────────────────────────────────
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 20 : 48,
                        vertical: isMobile ? 36 : 52,
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 1180,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionLabel(
                                  text: t('Misyonumuz', 'Our Mission')),
                              const SizedBox(height: 16),
                              Text(
                                t(
                                  'Öğrenci akademik hayatını\ndaha verimli kıl.',
                                  'Make student academic life\nmore efficient.',
                                ),
                                style: TextStyle(
                                  fontSize: isMobile ? 28 : 40,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0F0C29),
                                  height: 1.15,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: isSmall ? double.infinity : 620,
                                child: Text(
                                  t(
                                    'Uni Notes; öğrencilerin ders materyallerine kolayca erişmesini, notlarını güvenle paylaşmasını ve yapay zeka destekli içerik analiziyle kaliteli kaynakları ayırt etmesini sağlamak için tasarlandı.',
                                    'Uni Notes is designed to help students easily access course materials, share notes securely, and distinguish quality resources with AI-powered content analysis.',
                                  ),
                                  style: TextStyle(
                                    fontSize: isMobile ? 15 : 17,
                                    height: 1.7,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── FEATURES AS TIMELINE ──────────────────────────────────
                    Container(
                      color: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 20 : 48,
                        vertical: isMobile ? 40 : 60,
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 1180,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionLabel(
                                  text: t('Özellikler', 'Features')),
                              const SizedBox(height: 10),
                              Text(
                                t(
                                  'Platform nasıl çalışır?',
                                  'How does the platform work?',
                                ),
                                style: TextStyle(
                                  fontSize: isMobile ? 24 : 32,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F0C29),
                                ),
                              ),
                              const SizedBox(height: 32),
                              isSmall
                                  ? Column(
                                      children: _buildTimelineItems(
                                          isMobile, t),
                                    )
                                  : Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            children: _buildTimelineItems(
                                                false, t)
                                              .take(3)
                                              .toList(),
                                          ),
                                        ),
                                        const SizedBox(width: 40),
                                        Expanded(
                                          child: Column(
                                            children: _buildTimelineItems(
                                                false, t)
                                              .skip(3)
                                              .toList(),
                                          ),
                                        ),
                                      ],
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── STATS CARDS ──────────────────────────────────────────
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 20 : 48,
                        vertical: isMobile ? 36 : 52,
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 1180,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionLabel(
                                  text: t('Teknik', 'Technical')),
                              const SizedBox(height: 16),
                              Text(
                                t(
                                  'Rakamlarla Uni Notes',
                                  'Uni Notes in Numbers',
                                ),
                                style: TextStyle(
                                  fontSize: isMobile ? 24 : 32,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F0C29),
                                ),
                              ),
                              const SizedBox(height: 24),
                              isMobile
                                  ? Column(
                                      children: [
                                        _NumCard(
                                          value: 'PDF/DOCX',
                                          label: t('Desteklenen Format',
                                              'Supported Format'),
                                          accent: const Color(0xFF6C63FF),
                                        ),
                                        const SizedBox(height: 14),
                                        _NumCard(
                                          value: '%80+',
                                          label: t('Benzerlik Eşiği',
                                              'Similarity Threshold'),
                                          accent: const Color(0xFF10B981),
                                        ),
                                        const SizedBox(height: 14),
                                        _NumCard(
                                          value: t('Anlık', 'Real-time'),
                                          label: t('İçerik Analizi',
                                              'Content Analysis'),
                                          accent: const Color(0xFFF59E0B),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        Expanded(
                                          child: _NumCard(
                                            value: 'PDF/DOCX',
                                            label: t('Desteklenen Format',
                                                'Supported Format'),
                                            accent: const Color(0xFF6C63FF),
                                          ),
                                        ),
                                        const SizedBox(width: 18),
                                        Expanded(
                                          child: _NumCard(
                                            value: '%80+',
                                            label: t('Benzerlik Eşiği',
                                                'Similarity Threshold'),
                                            accent: const Color(0xFF10B981),
                                          ),
                                        ),
                                        const SizedBox(width: 18),
                                        Expanded(
                                          child: _NumCard(
                                            value: t('Anlık', 'Real-time'),
                                            label: t('İçerik Analizi',
                                                'Content Analysis'),
                                            accent: const Color(0xFFF59E0B),
                                          ),
                                        ),
                                      ],
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── CONTACT FORM ─────────────────────────────────────────
                    Container(
                      color: const Color(0xFF0F0C29),
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 20 : 48,
                        vertical: isMobile ? 48 : 72,
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 1180,
                          child: isSmall
                              ? Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    _ContactInfo(
                                        isMobile: isMobile, t: t),
                                    SizedBox(
                                        height: isMobile ? 32 : 40),
                                    _ContactForm(
                                      isMobile: isMobile,
                                      t: t,
                                      nameCtrl: _nameController,
                                      emailCtrl: _emailController,
                                      messageCtrl: _messageController,
                                      sending: _sending,
                                      sent: _formSent,
                                      onSend: _sendForm,
                                    ),
                                  ],
                                )
                              : Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: _ContactInfo(
                                          isMobile: false, t: t),
                                    ),
                                    const SizedBox(width: 60),
                                    Expanded(
                                      flex: 6,
                                      child: _ContactForm(
                                        isMobile: false,
                                        t: t,
                                        nameCtrl: _nameController,
                                        emailCtrl: _emailController,
                                        messageCtrl: _messageController,
                                        sending: _sending,
                                        sent: _formSent,
                                        onSend: _sendForm,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),

                    const CustomFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTimelineItems(
      bool isMobile, String Function(String, String) t) {
    final items = [
      _TimelineItem(
        number: '01',
        icon: Icons.cloud_upload_rounded,
        accent: const Color(0xFF6C63FF),
        title: t('Not Yükleme', 'Note Upload'),
        description: t(
          'PDF veya DOCX formatındaki ders notlarınızı sisteme kolayca ekleyin.',
          'Easily add your lecture notes in PDF or DOCX format to the system.',
        ),
      ),
      _TimelineItem(
        number: '02',
        icon: Icons.psychology_alt_rounded,
        accent: const Color(0xFF10B981),
        title: t('Yapay Zeka Analizi', 'AI Analysis'),
        description: t(
          'Yüklenen içerik yapay zeka tarafından analiz edilerek benzeri notlarla karşılaştırılır.',
          'Uploaded content is analyzed by AI and compared with similar notes.',
        ),
      ),
      _TimelineItem(
        number: '03',
        icon: Icons.manage_search_rounded,
        accent: const Color(0xFFF59E0B),
        title: t('Akıllı Filtreleme', 'Smart Filtering'),
        description: t(
          'Üniversite, bölüm, sınıf, dönem ve ders adına göre hızla arama yapın.',
          'Search quickly by university, department, grade, semester and course.',
        ),
      ),
      _TimelineItem(
        number: '04',
        icon: Icons.download_rounded,
        accent: const Color(0xFFEF4444),
        title: t('Erişim & İndirme', 'Access & Download'),
        description: t(
          'İhtiyacınız olan notlara ulaşın, indirin ve çalışmalarınıza devam edin.',
          'Access the notes you need, download them and continue your studies.',
        ),
      ),
      _TimelineItem(
        number: '05',
        icon: Icons.bookmark_added_rounded,
        accent: const Color(0xFF8B5CF6),
        title: t('Kişisel Liste', 'Personal List'),
        description: t(
          'Takip ettiğiniz dersleri kişisel listenize ekleyerek düzenli kalın.',
          'Stay organized by adding your followed courses to your personal list.',
        ),
      ),
      _TimelineItem(
        number: '06',
        icon: Icons.groups_rounded,
        accent: const Color(0xFF06B6D4),
        title: t('Akademik Topluluk', 'Academic Community'),
        description: t(
          'Öğrenciler arasındaki akademik dayanışmayı güçlendirin.',
          'Strengthen academic solidarity among students.',
        ),
      ),
    ];
    return items;
  }
}

// ── ABOUT HERO ────────────────────────────────────────────────────────────────
class _AboutHeroText extends StatelessWidget {
  final bool isMobile;
  final String Function(String, String) t;
  const _AboutHeroText({required this.isMobile, required this.t});

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
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(999),
            border:
                Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.school_rounded,
                  color: Color(0xFF6C63FF), size: 15),
              const SizedBox(width: 6),
              Text(
                t('Bitirme Projesi', 'Graduation Project'),
                style: const TextStyle(
                  color: Colors.white70,
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
            'Uni Notes\nhakkında.',
            'About\nUni Notes.',
          ),
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: isMobile ? 40 : 60,
            height: 1.08,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          t(
            'Öğrencilerin ders materyallerine daha hızlı, düzenli ve akıllı şekilde ulaşmasını sağlayan modern not paylaşım platformu.',
            'A modern note-sharing platform that enables students to access course materials faster, more organized and smarter.',
          ),
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: isMobile ? 15 : 17,
            height: 1.7,
            color: Colors.white.withOpacity(0.65),
          ),
        ),
      ],
    );
  }
}

class _AboutHeroVisual extends StatelessWidget {
  final bool isMobile;
  const _AboutHeroVisual({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 28 : 40),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(isMobile ? 28 : 36),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Container(
            width: isMobile ? 80 : 100,
            height: isMobile ? 80 : 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF302B63)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(isMobile ? 22 : 28),
            ),
            child: Icon(Icons.school_rounded,
                size: isMobile ? 40 : 52, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text(
            'Uni Notes',
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 22 : 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'v1.0.0',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          _AboutBadge(
              icon: Icons.psychology_alt_rounded,
              label: 'AI-Powered'),
          const SizedBox(height: 10),
          _AboutBadge(
              icon: Icons.flutter_dash_rounded,
              label: 'Flutter'),
          const SizedBox(height: 10),
          _AboutBadge(
              icon: Icons.cloud_rounded,
              label: 'Cloud Ready'),
        ],
      ),
    );
  }
}

class _AboutBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _AboutBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF6C63FF), size: 18),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}

// ── TIMELINE ITEM ────────────────────────────────────────────────────────────
class _TimelineItem extends StatelessWidget {
  final String number;
  final IconData icon;
  final Color accent;
  final String title;
  final String description;

  const _TimelineItem({
    required this.number,
    required this.icon,
    required this.accent,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: accent.withOpacity(0.3), width: 1.5),
                ),
                child: Icon(icon, color: accent, size: 24),
              ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      number,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: accent,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.55,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── NUM CARD ─────────────────────────────────────────────────────────────────
class _NumCard extends StatelessWidget {
  final String value;
  final String label;
  final Color accent;

  const _NumCard({
    required this.value,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 36,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 16),
          Text(value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: accent,
              )),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}

// ── CONTACT INFO ─────────────────────────────────────────────────────────────
class _ContactInfo extends StatelessWidget {
  final bool isMobile;
  final String Function(String, String) t;
  const _ContactInfo({required this.isMobile, required this.t});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isMobile
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withOpacity(0.2),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            t('İLETİŞİM', 'CONTACT').toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF9B96FF),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          t(
            'Bizimle\niletişime geç.',
            'Get in\ntouch with us.',
          ),
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: isMobile ? 28 : 36,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.15,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          t(
            'Öneri, geri bildirim veya iş birliği için mesaj gönderebilirsin.',
            'Send a message for suggestions, feedback, or collaboration.',
          ),
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: 15,
            height: 1.6,
            color: Colors.white.withOpacity(0.55),
          ),
        ),
        const SizedBox(height: 32),
        _InfoRow(
          icon: Icons.mail_outline_rounded,
          text: 'uninotes@edu.tr',
        ),
        const SizedBox(height: 14),
        _InfoRow(
          icon: Icons.location_on_outlined,
          text: t('Türkiye', 'Turkey'),
        ),
        const SizedBox(height: 14),
        _InfoRow(
          icon: Icons.code_rounded,
          text: t('Bitirme Projesi', 'Graduation Project'),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon,
              color: const Color(0xFF9B96FF), size: 18),
        ),
        const SizedBox(width: 12),
        Text(text,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            )),
      ],
    );
  }
}

// ── CONTACT FORM ──────────────────────────────────────────────────────────────
class _ContactForm extends StatelessWidget {
  final bool isMobile;
  final String Function(String, String) t;
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController messageCtrl;
  final bool sending;
  final bool sent;
  final VoidCallback onSend;

  const _ContactForm({
    required this.isMobile,
    required this.t,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.messageCtrl,
    required this.sending,
    required this.sent,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    if (sent) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
              color: const Color(0xFF10B981).withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: Color(0xFF10B981), size: 38),
            ),
            const SizedBox(height: 20),
            Text(
              t('Mesajın iletildi!', 'Message sent!'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              t(
                'En kısa sürede seninle iletişime geçeceğiz.',
                "We'll get back to you as soon as possible.",
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : 36),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          isMobile
              ? Column(
                  children: [
                    _FormField(
                      ctrl: nameCtrl,
                      hint: t('Ad Soyad', 'Full Name'),
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 14),
                    _FormField(
                      ctrl: emailCtrl,
                      hint: t('E-posta', 'Email'),
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _FormField(
                        ctrl: nameCtrl,
                        hint: t('Ad Soyad', 'Full Name'),
                        icon: Icons.person_outline_rounded,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _FormField(
                        ctrl: emailCtrl,
                        hint: t('E-posta', 'Email'),
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 14),
          _FormField(
            ctrl: messageCtrl,
            hint: t(
              'Mesajınızı buraya yazın...',
              'Write your message here...',
            ),
            icon: Icons.chat_bubble_outline_rounded,
            maxLines: 5,
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: sending ? null : onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF302B63)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: sending
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.send_rounded,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            t('Gönder', 'Send Message'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;

  const _FormField({
    required this.ctrl,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.35),
          fontSize: 15,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 8),
          child: Icon(icon,
              color: Colors.white.withOpacity(0.4), size: 20),
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 0, minHeight: 0),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 18, vertical: 16),
        filled: true,
        fillColor: Colors.white.withOpacity(0.07),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
              color: Color(0xFF6C63FF), width: 1.5),
        ),
      ),
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