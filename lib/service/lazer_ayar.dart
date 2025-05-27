import 'package:dio/dio.dart';
import 'package:makine/model/lazer_ayar_model.dart';

class LaserSettingsService {
  final Dio dio;

  LaserSettingsService(this.dio);

  Future<List<LazerAyar>> fetchSettings() async {
    final response = await dio.get('https://kardamiyim.com/laser/API/Controller.php?endpoint=ayar/get');
    if (response.statusCode == 200) {
      return (response.data as List).map((e) => LazerAyar.fromJson(e)).toList();
    } else {
      throw Exception('Ayarlar alınamadı');
    }
  }
}

class GCodeCekmeServisi {
  final Dio dio;

  GCodeCekmeServisi(this.dio);

  Future<List<String>> fetchGCodeler() async {
    final response = await dio.get(
      "https://kardamiyim.com/laser/API/Controller.php?endpoint=cron/generateGCodes",
      options: Options(validateStatus: (status) => true),
    );

    if (response.statusCode == 200 && response.data is Map && response.data.containsKey('cmd')) {
      final List<String> urls = List<String>.from(response.data['cmd']);
      return urls;
    } else {
      throw Exception("GCode URL'leri alınamadı");
    }
  }
}
