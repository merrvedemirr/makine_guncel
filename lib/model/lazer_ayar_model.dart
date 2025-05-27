// Lazer ayarları için model sınıfı
class LazerAyar {
  final String id;
  final String ayarAdi;
  final String lazerHizi;
  final String lazerGucu;
  final String createdAt;
  final String status;

  LazerAyar({
    required this.id,
    required this.ayarAdi,
    required this.lazerHizi,
    required this.lazerGucu,
    required this.createdAt,
    required this.status,
  });

  factory LazerAyar.fromJson(Map<String, dynamic> json) {
    return LazerAyar(
      id: json['id'] ?? '',
      ayarAdi: json['ayar_adi'] ?? '',
      lazerHizi: json['lazer_hizi'] ?? '',
      lazerGucu: json['lazer_gucu'] ?? '',
      createdAt: json['created_at'] ?? '',
      status: json['status'] ?? '',
    );
  }
}
