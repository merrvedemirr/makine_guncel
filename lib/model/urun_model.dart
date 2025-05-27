class Urun {
  final String id;
  final String urunAdi;
  final String urunResmi;
  final String createdAt;

  Urun({
    required this.id,
    required this.urunAdi,
    required this.urunResmi,
    required this.createdAt,
  });

  // JSON'dan nesneye dönüştürme
  factory Urun.fromJson(Map<String, dynamic> json) {
    return Urun(
      id: json['id'],
      urunAdi: json['urun_adi'],
      urunResmi: json['urun_resmi'],
      createdAt: json['created_at'],
    );
  }

  // Nesneden JSON'a dönüştürme
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'urun_adi': urunAdi,
      'urun_resmi': urunResmi,
      'created_at': createdAt,
    };
  }
}

class UrunResponse {
  final bool success;
  final List<Urun> data;

  UrunResponse({
    required this.success,
    required this.data,
  });

  factory UrunResponse.fromJson(Map<String, dynamic> json) {
    return UrunResponse(
      success: json['success'],
      data: (json['data'] as List).map((item) => Urun.fromJson(item)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data.map((item) => item.toJson()).toList(),
    };
  }
}
