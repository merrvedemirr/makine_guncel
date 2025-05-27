import 'package:dio/dio.dart';
import 'package:makine/utils/project_dio.dart';
import '../model/statistic_model.dart';
import 'package:flutter/material.dart';

abstract class StaticsService {
  Future<StatisticResponse?> getStatics({
    required String id,
  });
}

class StaticsServices extends StaticsService with ProjectDioMixin {
  //*http isteklerini yönetmek ve kolaylaştırmak için dio kullanıyoruz.
  static const String _staticPass = "busmZIMdnWpkQezUnrCXqtmeEmFqQDvgcstgEHIULzXmgfHqEO";
  late final Dio _dio;
  StaticsServices() {
    _dio = servicePath; // Mixin'den gelen değişken
  }

  @override
  Future<StatisticResponse?> getStatics({
    required String id,
  }) async {
    try {
      final response = await _dio.post(
        "?endpoint=user/stats",
        data: {
          "id": id,
          "pass": _staticPass,
        },
        options: Options(
          headers: {"Content-Type": "application/json"},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return StatisticResponse.fromJson(response.data);
      }
      return null;
    } catch (e) {
      // Hata yönetimi burada yapılabilir
      print("Statik veri çekme hatası: $e");
      return null;
    }
  }
}

class StatisticDetailDialog extends StatelessWidget {
  final List<Map<String, dynamic>> items; // Her model için bir map
  final String? tarih;

  const StatisticDetailDialog({
    super.key,
    required this.items,
    this.tarih,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.85;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).dialogBackgroundColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                'Ürün Detayları',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            if (tarih != null) ...[
              const SizedBox(height: 8),
              Center(child: Text('Tarih: $tarih', style: Theme.of(context).textTheme.titleMedium)),
            ],
            const SizedBox(height: 12),
            const Divider(),
            // Kaydırılabilir liste:
            SizedBox(
              height: 300, // Maksimum yükseklik, gerekirse artırabilirsin
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Model', item['model']),
                      _buildDetailRow('Detay', item['detay']),
                      _buildDetailRow('Ana Kategori', item['ana_kategori']),
                      _buildDetailRow('Alt Kategori', item['alt_kategori']),
                      _buildDetailRow('Adet', item['adet']),
                      _buildDetailRow('Kesim Sayısı', item['toplam_kesim_sayisi']),
                    ],
                  );
                },
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'TAMAM',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value?.toString() ?? '-',
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
