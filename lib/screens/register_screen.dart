import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/custom_header.dart';
import '../services/auth_service.dart';
import '../widgets/custom_footer.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String? selectedUniversity;
  String? selectedGrade;
  String? selectedFaculty;
  String? departmentValue;

  bool isLoading = false;
  String currentLanguage = 'TR';

  final List<String> universities = ['Erciyes Üniversitesi'];

  final List<String> grades = [
    'Hazırlık',
    '1. Sınıf',
    '2. Sınıf',
    '3. Sınıf',
    '4. Sınıf',
    '5. Sınıf',
    '6. Sınıf',
  ];

  final Map<String, Map<String, String>> _localizedValues = {
    'TR': {
      'title': 'Kayıt Ol',
      'subtitle': 'Üniversite not paylaşım platformuna katıl.',
      'fullName': 'Ad Soyad',
      'email': 'E-posta',
      'password': 'Şifre',
      'passwordHelper': 'En az 8 karakter, büyük-küçük harf, rakam ve özel karakter içermeli',
      'university': 'Üniversite',
      'selectUniversity': 'Üniversite seç',
      'grade': 'Sınıf',
      'selectGrade': 'Sınıf seç',
      'prevSelectUniversity': 'Önce üniversite seç',
      'prevSelectGrade': 'Önce sınıf seç',
      'prevSelectFaculty': 'Önce fakülte seç',
      'faculty': 'Fakülte / Yüksekokul',
      'department': 'Bölüm',
      'registerBtn': 'Kayıt Ol',
      'alreadyHaveAccount': 'Zaten hesabın var mı? Giriş Yap',
      'errorEmptyFields': 'Lütfen tüm alanları doldur.',
      'errorShortName': 'Ad soyad en az 3 karakter olmalı.',
      // GÜNCELLENDI
      'errorInvalidEmail': 'Lütfen geçerli bir Erciyes Üniversitesi mail adresi girin (@erciyes.edu.tr).',
      'errorWeakPassword': 'Şifre en az 8 karakter olmalı; büyük harf, küçük harf, rakam ve özel karakter içermeli.',
      'actionSuccess': 'İşlem tamamlandı',
      'errorPrefix': 'Hata: ',
    },
    'EN': {
      'title': 'Register',
      'subtitle': 'Join the university note-sharing platform.',
      'fullName': 'Full Name',
      'email': 'Email',
      'password': 'Password',
      'passwordHelper': 'At least 8 characters, uppercase, lowercase, number, and special character',
      'university': 'University',
      'selectUniversity': 'Select University',
      'grade': 'Grade',
      'selectGrade': 'Select Grade',
      'prevSelectUniversity': 'Select university first',
      'prevSelectGrade': 'Select grade first',
      'prevSelectFaculty': 'Select faculty first',
      'faculty': 'Faculty / School',
      'department': 'Department',
      'registerBtn': 'Register',
      'alreadyHaveAccount': 'Already have an account? Log In',
      'errorEmptyFields': 'Please fill in all fields.',
      'errorShortName': 'Full name must be at least 3 characters long.',
      // GÜNCELLENDI
      'errorInvalidEmail': 'Please enter a valid Erciyes University email address (@erciyes.edu.tr).',
      'errorWeakPassword': 'Password must be at least 8 characters; include uppercase, lowercase, number, and special character.',
      'actionSuccess': 'Action completed',
      'errorPrefix': 'Error: ',
    }
  };

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentLanguage = prefs.getString('language') ?? 'TR';
    });
  }

  String translate(String key) {
    return _localizedValues[currentLanguage]?[key] ?? key;
  }

  Map<String, List<String>> get activeFacultyDepartments => undergraduateDepartments;

  final Map<String, List<String>> undergraduateDepartments = {
    'TIP FAKÜLTESİ': ['TIP'],
    'MÜHENDİSLİK FAKÜLTESİ': [
      'BİLGİSAYAR MÜHENDİSLİĞİ',
      'BİYOMEDİKAL MÜHENDİSLİĞİ',
      'ÇEVRE MÜHENDİSLİĞİ',
      'ELEKTRİK-ELEKTRONİK MÜHENDİSLİĞİ',
      'ENDÜSTRİ MÜHENDİSLİĞİ',
      'ENDÜSTRİYEL TASARIM MÜHENDİSLİĞİ',
      'ENERJİ SİSTEMLERİ MÜHENDİSLİĞİ',
      'ENERJİ SİSTEMLERİ MÜHENDİSLİĞİ (İNGİLİZCE)',
      'GIDA MÜHENDİSLİĞİ',
      'HARİTA MÜHENDİSLİĞİ',
      'İNŞAAT MÜHENDİSLİĞİ',
      'MAKİNE MÜHENDİSLİĞİ',
      'MAKİNE MÜHENDİSLİĞİ (İNGİLİZCE)',
      'MEKATRONİK MÜHENDİSLİĞİ',
      'METALURJİ VE MALZEME MÜHENDİSLİĞİ',
      'TEKSTİL MÜHENDİSLİĞİ',
      'YAZILIM MÜHENDİSLİĞİ (İNGİLİZCE)',
    ],
    'İLAHİYAT FAKÜLTESİ': [
      'İLAHİYAT',
      'İLAHİYAT (M.T.O.K.)',
      'İLAHİYAT (M.T.O.K.) (İÖ)',
      'İLKÖĞRETİM DİN KÜLTÜRÜ VE AHLAK BİL. ÖĞR.',
    ],
    'MİMARLIK FAKÜLTESİ': [
      'ENDÜSTRİYEL TASARIM',
      'MİMARLIK',
      'ŞEHİR VE BÖLGE PLANLAMA',
    ],
    'GÜZEL SANATLAR FAKÜLTESİ': [
      'ÇİZGİ FİLM VE ANİMASYON',
      'GELENEKSEL TÜRK MÜZİĞİ',
      'GELENEKSEL TÜRK SANATLARI',
      'GRAFİK TASARIMI',
      'HEYKEL',
      'MÜZİK',
      'RESİM',
      'SERAMİK VE CAM',
    ],
    'VETERİNER FAKÜLTESİ': ['VETERİNER'],
    'EĞİTİM FAKÜLTESİ': [
      'ALMANCA ÖĞRETMENLİĞİ',
      'FEN BİLGİSİ ÖĞRETMENLİĞİ',
      'İLKÖĞRETİM MATEMATİK ÖĞRETMENLİĞİ',
      'İNGİLİZCE ÖĞRETMENLİĞİ',
      'OKUL ÖNCESİ ÖĞRETMENLİĞİ',
      'REHBERLİK VE PSİKOLOJİK DANIŞMANLIK',
      'SINIF ÖĞRETMENLİĞİ',
      'SOSYAL BİLGİLER ÖĞRETMENLİĞİ',
      'TÜRKÇE ÖĞRETMENLİĞİ',
    ],
    'İLETİŞİM FAKÜLTESİ': [
      'GAZETECİLİK',
      'GAZETECİLİK UZAKTAN ÖĞRETİM',
      'HALKLA İLİŞKİLER VE TANITIM',
      'HALKLA İLİŞKİLER VE TANITIM UZAKTAN ÖĞRETİM',
      'RADYO, TELEVİZYON VE SİNEMA',
      'RADYO, TELEVİZYON VE SİNEMA (UÖ)',
      'YENİ MEDYA VE İLETİŞİM',
    ],
    'FEN FAKÜLTESİ': [
      'ASTRONOMİ VE UZAY BİLİMLERİ',
      'BİYOLOJİ',
      'FİZİK',
      'KİMYA',
      'MATEMATİK',
      'MÜHENDİSLİK TEMEL BİLİM DERSLERİ',
    ],
    'EDEBİYAT FAKÜLTESİ': [
      'ÇERKEZ DİLİ VE KÜLTÜRÜ',
      'ÇİN DİLİ VE EDEBİYATI',
      'EĞİTİM PROGRAMLARI VE ÖĞRETİM',
      'ERMENİ DİLİ VE KÜLTÜRÜ',
      'FELSEFE',
      'İBRANİ DİLİ VE KÜLTÜRÜ',
      'İNGİLİZ DİLİ VE EDEBİYATI',
      'JAPON DİLİ VE EDEBİYATI',
      'KORE DİLİ VE EDEBİYATI',
      'RUS DİLİ VE EDEBİYATI',
      'SANAT TARİHİ',
      'SOSYOLOJİ',
      'TARİH',
      'TÜRK DİLİ VE EDEBİYATI',
      'TÜRK HALKBİLİMİ',
    ],
    'SAĞLIK BİLİMLERİ FAKÜLTESİ': [
      'BESLENME VE DİYETETİK',
      'HEMŞİRELİK',
    ],
    'HAVACILIK VE UZAY BİLİMLERİ FAKÜLTESİ': [
      'HAVACILIK ELEKTRİK VE ELEKTRONİĞİ',
      'HAVACILIK YÖNETİMİ',
      'UÇAK GÖVDE VE MOTOR BAKIMI',
      'UÇAK MÜHENDİSLİĞİ',
      'UZAY MÜHENDİSLİĞİ',
    ],
    'TURİZM FAKÜLTESİ': [
      'GASTRONOMİ VE MUTFAK SANATLARI',
      'TURİZM İŞLETMECİLİĞİ',
      'TURİZM REHBERLİĞİ',
    ],
    'SPOR BİLİMLERİ FAKÜLTESİ': [
      'ANTRENÖRLÜK EĞİTİMİ',
      'BEDEN EĞİTİMİ VE SPOR ÖĞRETMENLİĞİ',
      'REKREASYON',
      'SPOR YÖNETİCİLİĞİ',
    ],
    'HUKUK FAKÜLTESİ': ['HUKUK'],
    'ECZACILIK FAKÜLTESİ': ['ECZACILIK'],
    'DİŞ HEKİMLİĞİ FAKÜLTESİ': ['DİŞ HEKİMLİĞİ'],
    'ZİRAAT FAKÜLTESİ': [
      'BAHÇE BİTKİLERİ',
      'BİTKİ KORUMA',
      'BİYOSİSTEM MÜHENDİSLİĞİ',
      'TARIMSAL BİYOTEKNOLOJİ',
      'TARLA BİTKİLERİ',
      'TOPRAK BİLİMİ VE BİTKİ BESLEME',
      'ZOOTEKNİ',
    ],
    'SİVİL HAVACILIK YÜKSEKOKULU': ['SİVİL HAVACILIK'],
    'TURİZM İŞLETMECİLİĞİ VE OTELCİLİK Y.O.': [
      'TURİZM İŞLETMECİLİĞİ VE OTELCİLİK',
    ],
  };

  // GÜNCELLENDI: sadece @erciyes.edu.tr kabul eder
  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@erciyes\.edu\.tr$');
    return emailRegex.hasMatch(email);
  }

  bool isStrongPassword(String password) {
    final hasMinLength = password.length >= 8;
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    final hasDigit = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecialChar =
        RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-\\/\[\]=+;]').hasMatch(password);

    return hasMinLength &&
        hasUppercase &&
        hasLowercase &&
        hasDigit &&
        hasSpecialChar;
  }

  Future<void> registerUser() async {
    final fullName = fullNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final university = selectedUniversity ?? '';
    final department = departmentValue ?? '';

    if (fullName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        university.isEmpty ||
        selectedFaculty == null ||
        department.isEmpty ||
        selectedGrade == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translate('errorEmptyFields'))),
      );
      return;
    }

    if (fullName.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translate('errorShortName'))),
      );
      return;
    }

    if (!isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translate('errorInvalidEmail'))),
      );
      return;
    }

    if (!isStrongPassword(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translate('errorWeakPassword'))),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final result = await AuthService.register(
        fullName: fullName,
        email: email,
        password: password,
        university: university,
        department: department,
        grade: selectedGrade!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? translate('actionSuccess'))),
      );

      // GÜNCELLENDI: verify ekranına yönlendir
      if (result['needsVerification'] == true) {
        Navigator.pushNamed(
          context,
          '/verify-email',
          arguments: result['email'],
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${translate('errorPrefix')}$e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final facultyDepartments = selectedUniversity == 'Erciyes Üniversitesi'
        ? activeFacultyDepartments
        : <String, List<String>>{};

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Column(
        children: [
          const CustomHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 40, bottom: 0),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 520,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromARGB(18, 0, 0, 0),
                            blurRadius: 14,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            translate('title'),
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            translate('subtitle'),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 28),
                          TextField(
                            controller: fullNameController,
                            decoration: InputDecoration(
                              labelText: translate('fullName'),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: emailController,
                            decoration: InputDecoration(
                              labelText: translate('email'),
                              hintText: 'ornek@erciyes.edu.tr',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: translate('password'),
                              helperText: translate('passwordHelper'),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: selectedUniversity,
                            isExpanded: true,
                            items: universities.map((university) {
                              return DropdownMenuItem<String>(
                                value: university,
                                child: Text(university),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedUniversity = value;
                                selectedGrade = null;
                                selectedFaculty = null;
                                departmentValue = null;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: translate('university'),
                              hintText: translate('selectUniversity'),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: selectedGrade,
                            isExpanded: true,
                            items: grades.map((grade) {
                              return DropdownMenuItem<String>(
                                value: grade,
                                child: Text(grade),
                              );
                            }).toList(),
                            onChanged: selectedUniversity == null
                                ? null
                                : (value) {
                                    setState(() {
                                      selectedGrade = value;
                                      selectedFaculty = null;
                                      departmentValue = null;
                                    });
                                  },
                            decoration: InputDecoration(
                              labelText: translate('grade'),
                              hintText: selectedUniversity == null
                                  ? translate('prevSelectUniversity')
                                  : translate('selectGrade'),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: selectedFaculty,
                            isExpanded: true,
                            items: facultyDepartments.keys.map((faculty) {
                              return DropdownMenuItem<String>(
                                value: faculty,
                                child: Text(
                                  faculty,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: selectedUniversity == null || selectedGrade == null
                                ? null
                                : (value) {
                                    setState(() {
                                      selectedFaculty = value;
                                      departmentValue = null;
                                    });
                                  },
                            decoration: InputDecoration(
                              labelText: translate('faculty'),
                              hintText: selectedUniversity == null
                                  ? translate('prevSelectUniversity')
                                  : selectedGrade == null
                                      ? translate('prevSelectGrade')
                                      : translate('faculty'),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: departmentValue,
                            isExpanded: true,
                            items: (selectedFaculty == null
                                    ? <String>[]
                                    : facultyDepartments[selectedFaculty] ?? <String>[])
                                .map((department) {
                              return DropdownMenuItem<String>(
                                value: department,
                                child: Text(
                                  department,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: selectedUniversity == null ||
                                    selectedGrade == null ||
                                    selectedFaculty == null
                                ? null
                                : (value) {
                                    setState(() {
                                      departmentValue = value;
                                    });
                                  },
                            decoration: InputDecoration(
                              labelText: translate('department'),
                              hintText: selectedUniversity == null
                                  ? translate('prevSelectUniversity')
                                  : selectedGrade == null
                                      ? translate('prevSelectGrade')
                                      : selectedFaculty == null
                                          ? translate('prevSelectFaculty')
                                          : translate('department'),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : registerUser,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
                                  : Text(
                                      translate('registerBtn'),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/login');
                            },
                            child: Text(translate('alreadyHaveAccount')),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
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