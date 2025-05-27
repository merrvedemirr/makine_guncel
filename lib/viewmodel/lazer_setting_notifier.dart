// 📁 lib/notifier/laser_settings_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makine/service/lazer_ayar.dart';
import '../model/lazer_ayar_model.dart';

class LaserSettingsNotifier extends StateNotifier<AsyncValue<List<LazerAyar>>> {
  final LaserSettingsService service;

  LaserSettingsNotifier(this.service) : super(const AsyncLoading()) {
    fetchSettings(); // Otomatik yükleme
  }

  Future<void> fetchSettings() async {
    try {
      state = const AsyncLoading(); // loading durumuna al
      final settings = await service.fetchSettings();
      state = AsyncData(settings); // başarıyla geldiyse state'e yaz
    } catch (e, st) {
      state = AsyncError(e, st); // hata durumunda
    }
  }

  void refresh() => fetchSettings(); // manuel yenileme
}
