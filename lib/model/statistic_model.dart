class StatisticResponse {
  final bool status;
  final List<StatisticItem> daily;
  final List<StatisticItem> monthly;

  StatisticResponse({
    required this.status,
    required this.daily,
    required this.monthly,
  });

  factory StatisticResponse.fromJson(Map<String, dynamic> json) {
    return StatisticResponse(
      status: json['status'] ?? false,
      daily: (json['daily'] as List<dynamic>?)?.map((e) => StatisticItem.fromJson(e)).toList() ?? [],
      monthly: (json['monthly'] as List<dynamic>?)?.map((e) => StatisticItem.fromJson(e)).toList() ?? [],
    );
  }
}

class StatisticItem {
  final String kullaniciAdi;
  final String adi;
  final String soyadi;
  final String anaKategori;
  final String altKategori;
  final String model;
  final String detay;
  final String toplamKesimSayisi;
  final String? gun; // daily için
  final String? ay; // monthly için

  StatisticItem({
    required this.kullaniciAdi,
    required this.adi,
    required this.soyadi,
    required this.anaKategori,
    required this.altKategori,
    required this.model,
    required this.detay,
    required this.toplamKesimSayisi,
    this.gun,
    this.ay,
  });

  factory StatisticItem.fromJson(Map<String, dynamic> json) {
    return StatisticItem(
      kullaniciAdi: json['kullanici_adi'] ?? '',
      adi: json['adi'] ?? '',
      soyadi: json['soyadi'] ?? '',
      anaKategori: json['ana_kategori'] ?? '',
      altKategori: json['alt_kategori'] ?? '',
      model: json['model'] ?? '',
      detay: json['detay'] ?? '',
      toplamKesimSayisi: json['toplam_kesim_sayisi'] ?? '',
      gun: json['gun'],
      ay: json['ay'],
    );
  }
}
