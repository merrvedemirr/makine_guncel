// GCodeService için provider
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makine/model/bluetooth_device_model.dart';
import 'package:makine/model/lazer_ayar_model.dart';
import 'package:makine/service/komut_service.dart';
import 'package:makine/controller/bluetooth_controller.dart';
import 'package:makine/service/lazer_ayar.dart';
import 'package:makine/viewmodel/lazer_setting_notifier.dart';

final gCodeServiceProvider = Provider((ref) => GCodeService(Dio()));

//Butona tıklanabilir mi?
final lazerKesmeGucuProvider = StateProvider<double>((ref) => 50);
final lazerHizPage2Provider = StateProvider<double>((ref) => 50);

// Bağlı Bluetooth cihazını tutan state provider
final connectedBluetoothDeviceProvider = StateProvider<BluetoothDeviceModel?>((ref) => null);

// Bluetooth bağlantı durumunu izlemek için bir provider (gösterim kolaylığı için)
final isBluetoothConnectedProvider = StateProvider<bool>((ref) {
  return ref.watch(connectedBluetoothDeviceProvider) != null;
});

// BluetoothController provider
final bluetoothControllerProvider = Provider<BluetoothController>((ref) {
  return BluetoothController();
});

// Görüntü pozisyonu için provider
final imagePositionProvider = StateProvider<Offset>((ref) => const Offset(5, 5));

// Dönüş açısı için provider
final rotationProvider = StateProvider<double>((ref) => 0.0);

// Görüntünün gerçek koordinatlarını hesaplamak için provider
final actualCoordinatesProvider = Provider<Map<String, double>>((ref) {
  final position = ref.watch(imagePositionProvider);
  final containerSize = ref.watch(containerSizeProvider);
  final containerWidth = containerSize.width;
  final containerHeight = containerSize.height;

  // Statik değerler, gerçek mühendislik ölçeğine göre ayarlanmalı
  const LASER_WIDTH_MM = 350.0;
  const LASER_HEIGHT_MM = 250.0;
  const SAFE_MARGIN_MM = 0.0;

  double scaleX = (LASER_WIDTH_MM - SAFE_MARGIN_MM * 2) / containerWidth;
  double scaleY = (LASER_HEIGHT_MM - SAFE_MARGIN_MM * 2) / containerHeight;
// Önce sınır kontrolü yapmadan koordinatları hesapla
  double actualX = position.dx * scaleX + SAFE_MARGIN_MM;
  double actualY = position.dy * scaleY + SAFE_MARGIN_MM;

  // Sınır aşımı kontrolü
  bool isOutOfBounds = actualX > LASER_WIDTH_MM || actualY > LASER_HEIGHT_MM || actualX < 0 || actualY < 0;

  // Sınır aşımı durumunu güncelle
  ref.read(isOutOfBoundsProvider.notifier).state = isOutOfBounds;

  // Sınırlama yap
  actualX = actualX.clamp(0, LASER_WIDTH_MM);
  actualY = actualY.clamp(0, LASER_HEIGHT_MM);

  return {'x': actualX, 'y': actualY};
});

final processStatusProvider = StateProvider<String>((ref) => '');

final connectedDeviceProvider = StateProvider<BluetoothDeviceModel?>((ref) => null);

final isCompleteProvider = StateProvider<bool>((ref) => false);

final containerSizeProvider = StateProvider<Size>((ref) => const Size(300, 400)); // Varsayılan değer

final isCancelProvider = StateProvider<bool>((ref) => false);
final isSendingProvider = StateProvider<bool>((ref) => false);
final isLoadingProvider = StateProvider<bool>((ref) => false);

final lazerHiziProvider = StateProvider<double>((ref) => 50.0);
final lazerGucuProvider = StateProvider<double>((ref) => 50.0);

final laserSettingsNotifierProvider = StateNotifierProvider<LaserSettingsNotifier, AsyncValue<List<LazerAyar>>>(
  (ref) => LaserSettingsNotifier(LaserSettingsService(Dio())),
);

final selectedAyarProvider = StateProvider<LazerAyar?>((ref) => null);

final gcodeCekmeServisiProvider = Provider((ref) => GCodeCekmeServisi(Dio()));
// Add this near the other StateProvider declarations
final isOkGeldiProvider = StateProvider<bool>((ref) => false);

// Sınır aşımı için yeni bir provider
final isOutOfBoundsProvider = StateProvider<bool>((ref) => false);
