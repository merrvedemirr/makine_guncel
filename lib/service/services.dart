import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:makine/model/extra_detay_model.dart';
import 'package:makine/model/marka_model.dart';
import 'package:makine/model/model_model.dart';
import 'package:makine/model/urun_model.dart';
import 'package:makine/utils/ui_helpers.dart';

class DioClient {
  late final Dio dio;

  DioClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: "https://www.kardamiyim.com/laser", // Base URL
        connectTimeout: const Duration(seconds: 5000),
        receiveTimeout: const Duration(seconds: 5000),
        headers: {
          "Content-Type": "application/json",
        },
      ),
    );
  }

  Future<Response> get(String path) async {
    try {
      return await dio.get(path);
    } catch (e) {
      throw Exception("Dio Error: $e");
    }
  }
}

abstract class IServices {
  Future<List<EDetay>> fetchEDetay(String? modelId);
  Future<List<Marka>> fetchMarka(String modelID);
  Future<List<Model>> fetchModel(String? modelID);
  Future<List<Urun>> fetchUrun();
}

class Services extends IServices {
  final DioClient client;

  Services(this.client);

  @override
  Future<List<EDetay>> fetchEDetay(String? modelId) async {
    print("fetchEDetay çağrıldı - modelId: $modelId");

    // API çağrısı
    final response = await client.dio.get(
      '/alt_detay_api.php?model_id=$modelId',
    );

    // API yanıtını yazdır
    print("API yanıtı: ${response.data}");

    // Gelen veriyi kontrol et ve listeye dönüştür
    if (response.statusCode == 200 && response.data['data'] != null) {
      final data = response.data['data'] as List;
      return data.map((item) => EDetay.fromJson(item)).toList();
    } else {
      throw Exception('Veri alınamadı veya boş!');
    }
  }

  @override
  Future<List<Marka>> fetchMarka(String? modelID) async {
    // API çağrısı
    final response = await client.dio.get(
      '/anakategori_kirilim.php?model_id=$modelID',
    );

    // Gelen veriyi kontrol et ve listeye dönüştür
    if (response.statusCode == 200 && response.data['data'] != null) {
      final data = response.data['data'] as List;
      return data.map((item) => Marka.fromJson(item)).toList();
    } else {
      throw Exception('Veri alınamadı veya boş');
    }
  }

  @override
  Future<List<Model>> fetchModel(String? id) async {
    // API çağrısı
    final response = await client.dio.get(
      '/model_api_2.php?id=$id',
    );

    // Gelen veriyi kontrol et ve listeye dönüştür
    if (response.statusCode == 200 && response.data['data'] != null) {
      final data = response.data['data'] as List;
      return data.map((item) => Model.fromJson(item)).toList();
    } else {
      throw Exception('Veri alınamadı veya boş!');
    }
  }

  @override
  Future<List<Urun>> fetchUrun() async {
    final response = await client.dio.get('/anakategori_api.php'); // Doğru endpoint
    final data = response.data['data'] as List; // 'data' alanını liste olarak al
    return data.map((item) => Urun.fromJson(item)).toList(); // Listeyi Urun modeline çevir
  }

  void showError(BuildContext context, String message) {
    UIHelpers.showSnackBar(
      context,
      message: message,
      isError: true,
    );
  }

  void showSuccess(BuildContext context, String message) {
    UIHelpers.showSnackBar(
      context,
      message: message,
      isError: false,
    );
  }
}
