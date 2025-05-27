class EDetay {
  final int id;
  final int modelId;
  final String detayAdi;
  final String detayResmi;
  final String createdAt;
  final int turId;

  EDetay({
    required this.id,
    required this.modelId,
    required this.detayAdi,
    required this.detayResmi,
    required this.createdAt,
    required this.turId,
  });

  // JSON'dan nesneye dönüştürme
  factory EDetay.fromJson(Map<String, dynamic> json) {
    return EDetay(
      id: json['id'],
      modelId: json['model_id'],
      detayAdi: json['detay_adi'],
      detayResmi: json['detay_resmi'],
      createdAt: json['created_at'],
      turId: json['tur_id'],
    );
  }

  // Nesneden JSON'a dönüştürme
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'model_id': modelId,
      'detay_adi': detayAdi,
      'detay_resmi': detayResmi,
      'created_at': createdAt,
      'tur_id': turId,
    };
  }
}

class EDetayResponse {
  final bool success;
  final List<EDetay> data;

  EDetayResponse({
    required this.success,
    required this.data,
  });

  factory EDetayResponse.fromJson(Map<String, dynamic> json) {
    return EDetayResponse(
      success: json['success'],
      data: (json['data'] as List).map((item) => EDetay.fromJson(item)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data.map((item) => item.toJson()).toList(),
    };
  }
}
