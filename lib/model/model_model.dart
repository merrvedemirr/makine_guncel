class Model {
  final int id;
  final int anakategoriId;
  final String modelAdi;
  final String modelResmi;
  final String createdAt;

  Model({
    required this.id,
    required this.anakategoriId,
    required this.modelAdi,
    required this.modelResmi,
    required this.createdAt,
  });

  // JSON'dan nesneye dönüştürme
  factory Model.fromJson(Map<String, dynamic> json) {
    return Model(
      id: json['id'],
      anakategoriId: json['anakategori_id'],
      modelAdi: json['model_adi'],
      modelResmi: json['model_resmi'],
      createdAt: json['created_at'],
    );
  }

  // Nesneden JSON'a dönüştürme
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'anakategori_id': anakategoriId,
      'model_adi': modelAdi,
      'model_resmi': modelResmi,
      'created_at': createdAt,
    };
  }
}

class ModelResponse {
  final bool success;
  final List<Model> data;

  ModelResponse({
    required this.success,
    required this.data,
  });

  factory ModelResponse.fromJson(Map<String, dynamic> json) {
    return ModelResponse(
      success: json['success'],
      data: (json['data'] as List).map((item) => Model.fromJson(item)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data.map((item) => item.toJson()).toList(),
    };
  }
}
