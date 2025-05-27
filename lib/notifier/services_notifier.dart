import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makine/model/extra_detay_model.dart';
import 'package:makine/model/marka_model.dart';
import 'package:makine/model/model_model.dart';
import 'package:makine/model/urun_model.dart';
import 'package:makine/service/services.dart';

// DioClient Provider
final dioClientProvider = Provider((ref) => DioClient());

// Services Provider
final servicesProvider =
    Provider((ref) => Services(ref.read(dioClientProvider)));

// Urun FutureProvider
// Urun FutureProvider
final urunProvider = FutureProvider<List<Urun>>((ref) async {
  final service = ref.read(servicesProvider);
  return await service.fetchUrun();
});

final markaProvider =
    FutureProvider.family<List<Marka>, String?>((ref, modelID) async {
  final service = ref.read(servicesProvider);
  return await service.fetchMarka(modelID);
});

// Model FutureProvider
final modelProvider =
    FutureProvider.family<List<Model>, String?>((ref, id) async {
  final service = ref.read(servicesProvider);
  return await service.fetchModel(id);
});

// ExtraDetay FutureProvider
final extraDetayProvider1 =
    FutureProvider.family<List<EDetay>, String?>((ref, model_Id) async {
  final service = ref.read(servicesProvider);
  return await service.fetchEDetay(model_Id);
});
// ExtraDetay FutureProvider
// final extraDetayProvider2 = FutureProvider.family<List<EDetay>, String?>((ref, model_Id) async {
//   final service = ref.read(servicesProvider);
//   return await service.fetchEDetay(model_Id);
// });
// // ExtraDetay FutureProvider
// final extraDetayProvider3 = FutureProvider.family<List<EDetay>, String?>((ref, model_Id) async {
//   final service = ref.read(servicesProvider);
//   return await service.fetchEDetay(model_Id);
// });
// // ExtraDetay FutureProvider
// final extraDetayProvider4 = FutureProvider.family<List<EDetay>, String?>((ref, model_Id) async {
//   final service = ref.read(servicesProvider);
//   return await service.fetchEDetay(model_Id);
// });
