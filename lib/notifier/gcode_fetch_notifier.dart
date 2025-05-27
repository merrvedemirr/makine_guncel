// 📁 lib/notifier/gcode_cekme_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makine/service/lazer_ayar.dart';
import 'package:makine/viewmodel/provider.dart';

final gcodeCekmeNotifierProvider = StateNotifierProvider<GCodeCekmeNotifier, AsyncValue<List<String>>>((ref) {
  final service = ref.watch(gcodeCekmeServisiProvider);
  return GCodeCekmeNotifier(service);
});

class GCodeCekmeNotifier extends StateNotifier<AsyncValue<List<String>>> {
  final GCodeCekmeServisi servis;

  GCodeCekmeNotifier(this.servis) : super(const AsyncLoading());

  Future<void> fetchGCodeListesi() async {
    state = const AsyncLoading();
    try {
      final gcodeList = await servis.fetchGCodeler();
      if (gcodeList.isEmpty) {
        state = AsyncError("GCode listesi boş", StackTrace.current);
      } else {
        state = AsyncData(gcodeList);
      }
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
