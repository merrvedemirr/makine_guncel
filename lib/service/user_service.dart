import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:makine/logger.dart';

class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool success;

  ApiResponse.error(this.error)
      : success = false,
        data = null;
  ApiResponse.success(this.data)
      : success = true,
        error = null;
}

class UserService {
  final Dio _dio;
  final String _baseUrl = 'http://kardamiyim.com/laser/API/Controller.php';

  UserService() : _dio = Dio();

  // Add Credits
  Future<ApiResponse<Map<String, dynamic>>> addCredits({
    required int userId,
    required int amount,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl?endpoint=kontor/ekle',
        data: {
          'userId': userId,
          'miktar': amount,
        },
      );
      logger.i(response.statusCode);

      final responseData = response.data as Map<String, dynamic>;
      if (response.statusCode != 200) {
        return ApiResponse.error(responseData['message'] ?? 'Kontor ekleme başarısız');
      }
      return ApiResponse.success(responseData);
    } catch (e) {
      if (e is DioException) {
        return ApiResponse.error('Bağlantı hatası: ${e.message}');
      }
      return ApiResponse.error(e.toString());
    }
  }

  // User Login
  Future<ApiResponse<Map<String, dynamic>>> login(String username, String password) async {
    try {
      // İstek verisini kontrol edelim
      final requestData = {
        'kullaniciAdi': username,
        'sifre': password,
      };

      final response = await _dio.post(
        '$_baseUrl?endpoint=user/login',
        data: requestData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
      logger.i(response.data);

      final responseData = response.data as Map<String, dynamic>;

      // Başarılı login kontrolü - makineId ve kontor varsa başarılı
      if (responseData['makineId'] != null && responseData['kontor'] != null) {
        return ApiResponse.success(responseData);
      }

      return ApiResponse.error(responseData['error'] ?? 'Giriş başarısız');
    } catch (e) {
      if (e is DioException) {
        return ApiResponse.error('Bağlantı hatası: ${e.message}');
      }
      return ApiResponse.error(e.toString());
    }
  }

  // User Registration
  Future<ApiResponse<Map<String, dynamic>>> register({
    required String username,
    required String firstName,
    required String lastName,
    required String password,
    required String email,
    required String phone,
    required String machineUuid,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl?endpoint=user/register',
        data: {
          'kullaniciAdi': username,
          'adi': firstName,
          'soyadi': lastName,
          'sifre': password,
          'mail': email,
          'telefon': phone,
          'makineUuid': machineUuid,
        },
      );
      logger.i(response.data);
      final responseData = response.data as Map<String, dynamic>;

      // Başarılı mesajı kontrolü
      if (responseData['message'] == 'Kullanıcı başarıyla kaydedildi') {
        return ApiResponse.success(responseData);
      }

      return ApiResponse.error(responseData['error'] ?? 'Kayıt başarısız');
    } catch (e) {
      if (e is DioException) {
        return ApiResponse.error('Bağlantı hatası: ${e.message}');
      }
      return ApiResponse.error(e.toString());
    }
  }

  // Register Machine
  Future<Map<String, dynamic>> registerMachine({
    required String uuid,
    required int status,
    required String staticIp,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl?endpoint=machine/register',
        data: {
          'uuid': uuid,
          'status': status,
          'statikIp': staticIp,
        },
      );
      logger.i(response.data);
      final responseData = response.data as Map<String, dynamic>;
      _handleError(responseData);
      return responseData;
    } catch (e) {
      if (e is DioException) {
        throw Exception('Bağlantı hatası: ${e.message}');
      }
      rethrow;
    }
  }

  // Destek Talebi Gönderme
  Future<ApiResponse<Map<String, dynamic>>> sendSupportRequest({
    required int userId,
    required String request,
    String? imagePath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'id': userId,
        'request': request,
      });

      if (imagePath != null) {
        formData.files.add(MapEntry(
          'image',
          await MultipartFile.fromFile(imagePath, contentType: MediaType('image', imagePath.split('.').last)),
        ));
      }

      final response = await _dio.post(
        '$_baseUrl?endpoint=destek/ekle',
        data: formData,
      );
      logger.i(response.data);
      logger.i(response.statusCode);

      final responseData = response.data as Map<String, dynamic>;
      if (response.statusCode != 200 || responseData['error'] != null) {
        return ApiResponse.error(responseData['error'] ?? 'Destek talebi gönderilemedi');
      }
      return ApiResponse.success(responseData);
    } catch (e) {
      if (e is DioException) {
        return ApiResponse.error('Bağlantı hatası: ${e.message}');
      }
      return ApiResponse.error(e.toString());
    }
  }

  // Subtract Credits
  Future<Map<String, dynamic>> subtractCredits({
    required int userId,
    required int amount,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl?endpoint=kontor/cikar',
        data: {
          'userId': userId,
          'miktar': amount,
        },
      );

      final responseData = response.data as Map<String, dynamic>;
      _handleError(responseData);
      return responseData;
    } catch (e) {
      if (e is DioException) {
        throw Exception('Bağlantı hatası: ${e.message}');
      }
      rethrow;
    }
  }

  // API response kontrolü için yardımcı method
  void _handleError(Map<String, dynamic> response) {
    if (response['status'] != 'success') {
      throw Exception(response['message'] ?? 'Bir hata oluştu');
    }
  }
}
