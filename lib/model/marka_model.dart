class Marka {
  final int id;
  final int anakategoriId;
  final String markaAdi;
  final String markaResmi;
  final String createdAt;

  Marka({
    required this.id,
    required this.anakategoriId,
    required this.markaAdi,
    required this.markaResmi,
    required this.createdAt,
  });

  // JSON'dan nesneye dönüştürme
  factory Marka.fromJson(Map<String, dynamic> json) {
    return Marka(
      id: json['id'],
      anakategoriId: json['anakategori_id'],
      markaAdi: json['marka_adi'],
      markaResmi: json['marka_resmi'],
      createdAt: json['created_at'],
    );
  }

  // Nesneden JSON'a dönüştürme
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'anakategori_id': anakategoriId,
      'marka_adi': markaAdi,
      'marka_resmi': markaResmi,
      'created_at': createdAt,
    };
  }
}

// API cevabını listeye dönüştürmek için yardımcı sınıf
class MarkaResponse {
  final bool success;
  final List<Marka> data;

  MarkaResponse({
    required this.success,
    required this.data,
  });

  factory MarkaResponse.fromJson(Map<String, dynamic> json) {
    return MarkaResponse(
      success: json['success'],
      data: (json['data'] as List).map((item) => Marka.fromJson(item)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data.map((item) => item.toJson()).toList(),
    };
  }
}
