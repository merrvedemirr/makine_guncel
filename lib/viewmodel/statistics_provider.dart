import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makine/model/statistic_model.dart';
import 'package:makine/service/statics_service.dart';

// StaticsServices örneği
final staticsServiceProvider = Provider<StaticsServices>((ref) => StaticsServices());

// Kullanıcı id ile istatistik verisi çeken provider
final statisticsProvider = FutureProvider.family<StatisticResponse?, String>((ref, userId) async {
  final staticsService = ref.read(staticsServiceProvider);
  return await staticsService.getStatics(id: userId);
});
