class GCodeResponse {
  final bool success;
  final List<GCodeData> data;

  GCodeResponse({required this.success, required this.data});

  factory GCodeResponse.fromJson(Map<String, dynamic> json) {
    return GCodeResponse(
      success: json['success'],
      data: (json['data'] as List).map((item) => GCodeData.fromJson(item)).toList(),
    );
  }
}

class GCodeData {
  final int id;
  final int detayAltKategoriId;
  final String gcodeDetay;
  final int status;

  GCodeData({
    required this.id,
    required this.detayAltKategoriId,
    required this.gcodeDetay,
    required this.status,
  });

  factory GCodeData.fromJson(Map<String, dynamic> json) {
    return GCodeData(
      id: json['id'],
      detayAltKategoriId: json['detay_alt_kategori_id'],
      gcodeDetay: json['gcode_detay'],
      status: json['status'],
    );
  }
}
