class PersonModel {
  final String kullaniciAdi;
  final String isim;
  final String telNo;
  final String mail;
  final String adress;

  PersonModel({
    required this.kullaniciAdi,
    required this.isim,
    required this.telNo,
    required this.mail,
    required this.adress,
  });

  // JSON'dan nesneye dönüştürme metodu
  factory PersonModel.fromJson(Map<String, dynamic> json) {
    return PersonModel(
      kullaniciAdi: json['kullaniciAdi'],
      isim: json['isim'],
      telNo: json['telNo'],
      mail: json['mail'],
      adress: json['adress'],
    );
  }

  // Nesneden JSON'a dönüştürme metodu
  Map<String, dynamic> toJson() {
    return {
      'kullaniciAdi': kullaniciAdi,
      'isim': isim,
      'telNo': telNo,
      'mail': mail,
      'adress': adress,
    };
  }
}
