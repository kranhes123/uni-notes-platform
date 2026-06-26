import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/custom_header.dart';
import '../widgets/custom_footer.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final codeController = TextEditingController();
  bool isLoading = false;

  Future<void> verifyCode() async {
    final code = codeController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen 6 haneli kodu girin.')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await AuthService.verifyEmail(
        email: widget.email,
        code: code,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('E-posta doğrulandı! Giriş yapabilirsiniz.')),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Kod hatalı.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth > 700 ? 480.0 : screenWidth * 0.92;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Column(
        children: [
          const CustomHeader(),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: Container(
                              width: cardWidth,
                              padding: const EdgeInsets.all(36),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color.fromARGB(20, 0, 0, 0),
                                    blurRadius: 20,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // İkon
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.indigo.shade50,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.mark_email_read_outlined,
                                      color: Colors.indigo,
                                      size: 40,
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Başlık
                                  const Text(
                                    'E-posta Doğrulama',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Açıklama
                                  RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Color(0xFF6B7280),
                                        height: 1.6,
                                      ),
                                      children: [
                                        const TextSpan(text: 'Doğrulama kodu '),
                                        TextSpan(
                                          text: widget.email,
                                          style: const TextStyle(
                                            color: Colors.indigo,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const TextSpan(
                                          text: ' adresine gönderildi.\n6 haneli kodu aşağıya girin.',
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 32),

                                  // Kod alanı
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9FAFB),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFFE5E7EB)),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: TextField(
                                      controller: codeController,
                                      keyboardType: TextInputType.number,
                                      maxLength: 6,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 32,
                                        letterSpacing: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF111827),
                                      ),
                                      decoration: const InputDecoration(
                                        counterText: '',
                                        hintText: '······',
                                        hintStyle: TextStyle(
                                          fontSize: 32,
                                          letterSpacing: 12,
                                          color: Color(0xFFD1D5DB),
                                          fontWeight: FontWeight.bold,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Kod süresi bilgisi
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.access_time_rounded,
                                          size: 14, color: Color(0xFF9CA3AF)),
                                      SizedBox(width: 4),
                                      Text(
                                        'Kod 15 dakika geçerlidir.',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF9CA3AF),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 28),

                                  // Doğrula butonu
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: isLoading ? null : verifyCode,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.indigo,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 18),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: isLoading
                                          ? const SizedBox(
                                              height: 22,
                                              width: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text(
                                              'Doğrula',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Geri dön
                                  TextButton.icon(
                                    onPressed: () =>
                                        Navigator.pushNamedAndRemoveUntil(
                                            context, '/login', (r) => false),
                                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                                    label: const Text('Giriş sayfasına dön'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        const CustomFooter(),
                      ],
                    ),
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