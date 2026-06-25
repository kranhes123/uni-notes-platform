import 'package:flutter/foundation.dart';

/// Uygulama genelinde "oturum durumu değişti" (giriş yapıldı / çıkış yapıldı)
/// haberini dinleyen ekranlara duyurmak için kullanılan basit bir singleton.
///
/// KULLANIM:
/// Giriş yap / çıkış yap işlemini yaptığınız yerde (örn. CustomHeader
/// içindeki "Çıkış Yap" butonunun onTap'inde), SharedPreferences'ı
/// güncelledikten SONRA şu satırı ekleyin:
///
///   await prefs.remove('email'); // veya setString('email', ...)
///   SessionNotifier.instance.notifyChanged();
///
/// Bu sayede DerslerimScreen (ve dinleyen diğer ekranlar) sayfa yeniden
/// kurulmadan (initState tekrar çalışmadan) anında kendini günceller.
class SessionNotifier extends ChangeNotifier {
  SessionNotifier._internal();

  static final SessionNotifier instance = SessionNotifier._internal();

  /// Giriş veya çıkış işleminden sonra bunu çağırın.
  void notifyChanged() {
    notifyListeners();
  }
}