import 'package:dio/dio.dart';
import 'package:makine/logger.dart';
import 'package:makine/model/gcode_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// GCode detaylarını satır satır böler
List<String> extractGCodeLines(String gcodeDetay) {
  return gcodeDetay.split('\n').map((line) => line.trim()).toList();
}

/// API yanıtları için model sınıfı
class ApiResponse {
  final bool success;
  final String? errorMessage;

  ApiResponse({
    required this.success,
    this.errorMessage,
  });
}

class GCodeService {
  final Dio dio;
  bool _isSending = false;

  GCodeService(this.dio);

  /// GCode'ları fetch eder
  Future<List<String>> fetchGCode(String kategorId) async {
    try {
      final response = await dio.get('https://www.kardamiyim.com/laser/gcode_api.php?detay_alt_kategori_id=$kategorId');
      if (response.statusCode == 200) {
        final data = response.data;
        final gCodeResponse = GCodeResponse.fromJson(data);

        if (gCodeResponse.success && gCodeResponse.data.isNotEmpty) {
          // İlk veri setinin GCode detayını al
          return extractGCodeLines(gCodeResponse.data.first.gcodeDetay);
        }
      }
      throw Exception('GCode fetch başarısız.');
    } catch (e) {
      print('GCode fetch hatası: $e');
      return [];
    }
  }

  Future<void> koordinatGonder(double x, double y, int modelId) async {
    try {
      final response = await dio.post('/koordinat-guncelle', data: {
        'x_koordinat': x,
        'y_koordinat': y,
        'model_id': modelId,
      });

      if (response.statusCode != 200) {
        throw Exception('Koordinat güncellenirken hata oluştu');
      }
    } catch (e) {
      throw Exception('Koordinat gönderilirken hata: $e');
    }
  }

  /// Tüm GCode satırlarını sırasıyla gönderir
  Future<void> sendAllGCodeLines(List<String> lines) async {
    _isSending = true;
    for (String line in lines) {
      if (!_isSending) break;
      if (line.isNotEmpty) {
        await sendGCodeLine(line);
        await Future.delayed(const Duration(milliseconds: 1)); // Gecikme ekleyebilirsiniz
      }
    }
    _isSending = false;
    print('Tüm GCode komutları gönderildi.');
  }

  /// GCode komut satırını POST ile gönderir
  Future<void> sendGCodeLine(String line) async {
    try {
      final response = await dio.post(
        'http://192.168.89.155/command?cmd=$line',
      );
      if (response.statusCode == 200) {
        print('Komut gönderildi: $line');
      } else {
        print('Komut gönderim hatası: ${response.statusCode} - $line');
      }
    } catch (e) {
      print('Komut gönderim sırasında hata: $e');
    }
  }

  /// Lazer kesim verilerini API'ye gönderir
  Future<ApiResponse> sendLazerKesimData({
    required String gcodeId,
    required String lazerHiz,
    required String lazerGucu,
    required String aci,
    required String x,
    required String y,
    required String kontor,
  }) async {
    try {
      final userId = await _getUserId();
      final makineId = await _getMakineId();

      final Map<String, dynamic> data = {
        'user_id': userId,
        'makine_id': makineId,
        'gcode_id': gcodeId,
        'lazer_hiz': lazerHiz,
        'lazer_gucu': lazerGucu,
        'aci': aci,
        'x': x,
        'y': y,
        'kontor': kontor,
      };

      logger.i(data);
      final response = await dio.post(
        "https://kardamiyim.com/laser/API/Controller.php?endpoint=lazer/add",
        data: data,
        options: Options(
          validateStatus: (status) {
            return true;
          },
        ),
      );
      logger.i(response.data);
      logger.i(response.statusCode);

      // API yanıtını kontrol et
      if (response.statusCode == 200) {
        // Yanıt içinde hata mesajı var mı kontrol et
        if (response.data is Map && response.data.containsKey('error')) {
          return ApiResponse(success: false, errorMessage: response.data['error']);
        }

        print('Lazer kesim verileri başarıyla gönderildi');
        return ApiResponse(success: true);
      } else {
        print('Lazer kesim verileri gönderilirken hata: ${response.statusCode}');
        logger.e('Lazer kesim verileri gönderilirken hata: ${response.data}');
        return ApiResponse(success: false, errorMessage: 'Sunucu hatası: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Lazer kesim verileri gönderilirken hata: ${e.toString()}');
      return ApiResponse(success: false, errorMessage: 'Bağlantı hatası: $e');
    }
  }

  /// Gönderim işlemini durdurur
  void stopSending() {
    _isSending = false;
    print('GCode gönderimi durduruldu.');
  }

  Future<String?> _getMakineId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('makineId');
    } catch (e) {
      print('Makine ID alınamadı: $e');
      return null;
    }
  }

  Future<String?> _getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('userId');
    } catch (e) {
      print('Kullanıcı ID alınamadı: $e');
      return null;
    }
  }
}
