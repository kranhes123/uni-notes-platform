import 'package:flutter/material.dart';
import '../services/auth_service.dart';

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
    final cardWidth = screenWidth > 700 ? 450.0 : screenWidth * 0.92;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Center(
        child: Container(
          width: cardWidth,
          padding: const EdgeInsets.all(32),
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
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_email_read_outlined,
                    color: Colors.indigo, size: 36),
              ),
              const SizedBox(height: 20),
              const Text(
                'E-posta Doğrulama',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                '${widget.email} adresine gönderilen 6 haneli kodu girin.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '------',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text('Doğrula', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}