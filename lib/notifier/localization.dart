import 'package:makine/notifier/language_notifier.dart';

class AppLocalization {
  static const Map<AppLanguage, Map<String, String>> localizedStrings = {
    AppLanguage.english: {
      "siniflandirma": "Classification",
      "istatistik": "Statistics",
      "profil": "Profile",
      "search": "Search in phone model",
      "dailyStatistic": "Daily statistics",
      "monthStatistic": "Monthly statistics",
      "date": "Date",
      "satisHacmi": "Sales Volume",
      "kisiselMerkez": "Personal Center",
      "hesabim": "My Account",
      "parameterAyarla": "Set Parameters",
      "dilAyarla": "Language Settings",
      "makineBilgi": "About This Machine",
      "baglandi": "Connected",
      "cikis": "Log Out",
      "surum": "Version",
      "kisiselVeri": "Personal Data",
      "kullaniciAdi": "Username",
      "isim": "Name",
      "cepTel": "Mobile Phone Number",
      "ePosta": "Email",
      "adres": "Address",
      "kayitEt": "Save",
      "dilAyarlari": "Language Settings",
      "destekTalebi": "Support"
    },
    AppLanguage.turkish: {
      "siniflandirma": "Sınıflandırma",
      "istatistik": "İstatistik",
      "profil": "Profil",
      "search": "Telefon modelinde ara",
      "dailyStatistic": "Günlük istatistikler",
      "monthStatistic": "Aylık istatistikler",
      "date": "Tarih",
      "satisHacmi": "Satış Hacmi",
      "kisiselMerkez": "Kişisel Merkez",
      "hesabim": "Hesabım",
      "parameterAyarla": "Parametreleri ayarlama",
      "dilAyarla": "Dil ayarları",
      "makineBilgi": "Bu makine hakkında",
      "baglandi": "Bağlandı",
      "cikis": "Çıkış Yap",
      "surum": "Sürüm",
      "kisiselVeri": "Kişisel Veri",
      "kullaniciAdi": "Kullanıcı Adı",
      "isim": "İsim",
      "cepTel": "Cep telefon no",
      "ePosta": "Eposta",
      "adres": "Adres",
      "kayitEt": "Kayıt etmek",
      "dilAyarlari": "Dil Ayarları",
      "destekTalebi": "Destek Talebi",
      "kalanKontor": "Kalan Kontör",
      "kontorHakkiTalepEt": "Kontör Hakkı Talep Et"
    },
  };

  // Dil seçimine göre metinleri al
  static String getString(AppLanguage language, String key) {
    return localizedStrings[language]?[key] ?? key;
  }
}
