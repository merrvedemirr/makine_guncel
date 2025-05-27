import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makine/model/extra_detay_model.dart';
import 'package:makine/screens/home_page.dart';
import 'package:makine/screens/makineAyarlari/makine_gcode_gonder_screen.dart';
import 'package:makine/utils/ui_helpers.dart';
import 'package:makine/viewmodel/custom_pageroutebuilder.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';
import 'package:makine/viewmodel/provider.dart';
import 'package:dio/dio.dart';

class ModelYerlestirme extends ConsumerStatefulWidget {
  final List<EDetay> data;
  const ModelYerlestirme({super.key, required this.data});

  @override
  ConsumerState<ModelYerlestirme> createState() => _ModelYerlestirmeState();
}

class _ModelYerlestirmeState extends ConsumerState<ModelYerlestirme> {
  static const double imageWidth = 100.0;
  static const double imageHeight = 100.0;
  double step = 2.0;

  final TransformationController _transformationController = TransformationController();

  bool _isMirrored = false;
  bool _isImageLoading = true;
  bool _hasError = false;
  late final StreamSubscription<bool> _connectionSubscription;
  final GlobalKey _containerKey = GlobalKey();
  StreamSubscription<String>? _bluetoothDataSubscription;

  // initState'te provider'ları başlatalım
  @override
  void initState() {
    super.initState();

    // Provider'ları başlangıç değerleriyle ayarla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(imagePositionProvider.notifier).state = const Offset(5, 5);
      ref.read(rotationProvider.notifier).state = 0.0;
      // Reset isOkGeldi state
      ref.read(isOkGeldiProvider.notifier).state = false;

      // Sayfa açıldığında Bluetooth bağlantısını kontrol et
      _checkBluetooth();
      // Dinlemeyi başlat
      _startConnectionListener();

      // Send initial commands if bluetooth is connected
      if (ref.read(isBluetoothConnectedProvider)) {
        _sendInitialCommands();
      }
    });

    // // Ekranı yatay moda sabitle
    // SystemChrome.setPreferredOrientations([
    //   DeviceOrientation.landscapeLeft,
    //   DeviceOrientation.landscapeRight,
    // ]);
  }

  void _startConnectionListener() {
    final controller = ref.read(bluetoothControllerProvider);
    _connectionSubscription = controller.connectionStatusStream.listen((isConnected) {
      ref.read(isBluetoothConnectedProvider.notifier).state = isConnected;

      if (!isConnected && mounted) {
        _checkBluetooth();
      }
    });
  }

  void _checkBluetooth() {
    final controller = ref.read(bluetoothControllerProvider);
    final isConnected = controller.isConnected;

    // Provider durumunu güncelle
    ref.read(isBluetoothConnectedProvider.notifier).state = isConnected;

    if (!isConnected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false, // Kullanıcı dışarı tıklayarak kapatamaz
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.bluetooth_disabled_outlined,
                  color: Colors.blue,
                ),
                SizedBox(
                  width: 20,
                ),
                Text(
                  'Uyarı',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.blue),
                ),
              ],
            ),
            content: Text(
              'Bluetooth Bağlantısı Yok. Lütfen Bağlantınızı Kontrol Ediniz.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            actions: [
              TextButton(
                style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.blue), borderRadius: BorderRadius.circular(20))),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Kapat',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.blue),
                ),
              ),
            ],
          ),
        );
      });
    }
  }

  Future<void> _sendInitialCommands() async {
    try {
      // İlk komut: $H
      await _sendGCodeCommand('\$H');
      await _waitForOkResponse(false);

      // İkinci komut: G92 X0 Y0
      await _sendGCodeCommand('\$G92 X0 Y0');
      await _waitForOkResponse(true);

      // Eğer buraya kadar geldiyse OK gelmiştir
      ref.read(isOkGeldiProvider.notifier).state = true;
    } catch (e) {
      print('Error sending initial commands: $e');
      ref.read(isOkGeldiProvider.notifier).state = false;
    }
  }

  Future<void> _waitForOkResponse(bool komut2) async {
    final controller = ref.read(bluetoothControllerProvider);
    final stream = controller.getDataStream(); // null değil, direkt alınabilir

    bool receivedOk = false;

    try {
      await Future.any([
        Future(() async {
          _bluetoothDataSubscription = stream.listen(
            (data) {
              print("Gelen veri: $data");

              if (!receivedOk && data.toLowerCase().contains('ok')) {
                receivedOk = true;
                if (komut2) {
                  if (mounted) {
                    UIHelpers.showSnackBar(
                      context,
                      message: 'İkinci OK yanıtı alındı',
                      isError: false,
                    );
                    ref.read(isOkGeldiProvider.notifier).state = true;
                  }
                }
              }
            },
            onError: (error) {
              print('Veri akışı hatası: $error');
              throw error;
            },
            onDone: () {
              print('Bağlantı kapandı');
            },
            cancelOnError: true,
          );

          // Wait until we receive OK
          while (!receivedOk) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
        }),
        Future.delayed(const Duration(seconds: 5)), // Zaman aşımı
      ]);

      if (!receivedOk) {
        throw TimeoutException('OK yanıtı gelmedi (timeout)');
      }
    } finally {
      // await subscription?.cancel();
    }
  }

  // Görüntü hareketi için metot
  void _updateImagePosition(DragUpdateDetails details, double areaWidth, double areaHeight) {
    // Bluetooth bağlantısı yoksa işlem yapma
    if (!ref.read(isBluetoothConnectedProvider)) {
      //_showMessage('Bluetooth bağlantınız yok! Lütfen önce bağlantı kurun.', true);
      return;
    }

    final currentPosition = ref.read(imagePositionProvider);

    // Gri container'ın boyutunu al
    final RenderBox? box = _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final containerSize = box.size;

    // Yeni pozisyonu hesapla
    double newX = currentPosition.dx + details.delta.dx;
    double newY = currentPosition.dy + details.delta.dy;

    // Sınır kontrolü
    if (newX < 0) newX = 0;
    if (newY < 0) newY = 0;
    if (newX > areaWidth - imageWidth) newX = areaWidth - imageWidth;
    if (newY > areaHeight - imageHeight) newY = areaHeight - imageHeight;

    // Provider'ı güncelle
    ref.read(imagePositionProvider.notifier).state = Offset(newX, newY);

    // GCode komutlarını gönder
    _sendGCodeCommand('G90');

    // Gerçek koordinatları hesapla
    final actualCoordinates = ref.read(actualCoordinatesProvider);
    _sendGCodeCommand(
        'G1 X${actualCoordinates['x']!.toStringAsFixed(2)} Y${actualCoordinates['y']!.toStringAsFixed(2)} F100');
  }

  @override
  Widget build(BuildContext context) {
    //final containerWidth = MediaQuery.of(context).size.width;
    //final containerHeight = MediaQuery.of(context).size.height;

    // Provider'lardan değerleri oku
    final position = ref.watch(imagePositionProvider);
    final rotation = ref.watch(rotationProvider);
    final isBluetoothConnected = ref.watch(isBluetoothConnectedProvider);
    final isOkGeldi = ref.watch(isOkGeldiProvider);
    final isOutOfBounds = ref.watch(isOutOfBoundsProvider);
    final EDetay selectedDetail = widget.data.isNotEmpty
        ? widget.data.first
        : EDetay(
            id: 0,
            modelId: 0,
            detayAdi: "Placeholder",
            detayResmi: "https://via.placeholder.com/150", // Varsayılan bir resim
            createdAt: "",
            turId: 0,
          );

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 226, 226, 226),
        appBar: AppBar(
          title: const Text('Model Yerleştirme'),
          actions: [
            IconButton(
              icon: const Icon(Icons.flip),
              onPressed: isBluetoothConnected ? _toggleMirror : null,
              tooltip: 'Y eksenine göre simetri',
            ),
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {
                ref.read(imagePositionProvider.notifier).state = const Offset(5, 5); // veya Offset(0, 0)
                ref.read(rotationProvider.notifier).state = 0.0;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomePage()),
                  (route) => false,
                );
              },
              tooltip: 'Ana Sayfa',
            ),
            //!KİLİT KALDIRMA
            IconButton(
              icon: const Icon(Icons.lock),
              onPressed: isBluetoothConnected ? () => _sendGCodeCommand('\$X') : null,
            ),
            //! DENEME GCODE GÖNDERME
            TextButton(
                onPressed: isBluetoothConnected ? () => testGCode(selectedDetail.modelId) : null,
                child: Text(
                  "Dene",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                ))
          ],
        ),
        body: Column(
          children: [
            // Sol panel (model yerleştirme alanı)
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final areaWidth = constraints.maxWidth;
                  final areaHeight = constraints.maxHeight;
                  // Provider'ı güncelle
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref.read(containerSizeProvider.notifier).state = Size(areaWidth, areaHeight);
                  });
                  return Stack(
                    children: [
                      Container(
                        key: _containerKey,
                        width: areaWidth,
                        height: areaHeight,
                        color: Colors.grey.shade300,
                        child: Stack(
                          children: [
                            Positioned(
                              left: position.dx,
                              top: position.dy,
                              child: GestureDetector(
                                onPanUpdate: (isBluetoothConnected && isOkGeldi)
                                    ? (details) => _updateImagePosition(details, areaWidth, areaHeight)
                                    : null,
                                child: Transform.rotate(
                                  angle: rotation * (pi / 180),
                                  alignment: Alignment.center,
                                  child: Container(
                                    width: imageWidth,
                                    height: imageHeight,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image(
                                        image: NetworkImage(selectedDetail.detayResmi),
                                        fit: BoxFit.contain,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            _isImageLoading = false;
                                            return child;
                                          }
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded /
                                                      loadingProgress.expectedTotalBytes!
                                                  : null,
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          _hasError = true;
                                          return Container(
                                            color: Colors.grey[300],
                                            child: const Center(
                                              child: Icon(
                                                Icons.error_outline,
                                                color: Colors.red,
                                                size: 30,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Bluetooth bağlantısı yoksa sönük bir overlay göster
                      //!DEĞİŞTİRİLDİ
                      if (!isBluetoothConnected)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withOpacity(0.3),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bluetooth_disabled, size: 50, color: Colors.white),
                                  SizedBox(height: 10),
                                  Text(
                                    'Bluetooth Bağlantısı Gerekli',
                                    style: TextStyle(color: Colors.white, fontSize: 18),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            // Sağ panel (kontroller)
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.3,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      //!Açı Sıfırlama ALanı
                      Column(
                        children: [
                          Row(
                            children: [
                              InkWell(
                                onTap: isBluetoothConnected
                                    ? () {
                                        final currentRotation = ref.read(rotationProvider);
                                        ref.read(rotationProvider.notifier).state = (currentRotation - 1) % 360;
                                      }
                                    : null,
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.remove_circle_outline,
                                    size: 25,
                                    color: isBluetoothConnected ? Colors.black : Colors.grey,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SleekCircularSlider(
                                  appearance: CircularSliderAppearance(
                                    customWidths: CustomSliderWidths(
                                      trackWidth: 4,
                                      progressBarWidth: 4,
                                      shadowWidth: 3,
                                    ),
                                    customColors: CustomSliderColors(
                                      trackColor: Colors.grey[300],
                                      progressBarColor: isBluetoothConnected ? Colors.blue : Colors.grey,
                                      shadowColor: (isBluetoothConnected ? Colors.blue : Colors.grey).withOpacity(0.2),
                                    ),
                                    startAngle: 180,
                                    angleRange: 360,
                                    size: 60.0,
                                  ),
                                  min: 0,
                                  onChangeEnd: isBluetoothConnected
                                      ? (value) {
                                          ref.read(rotationProvider.notifier).state = value;
                                        }
                                      : null,
                                  onChangeStart: isBluetoothConnected
                                      ? (value) {
                                          ref.read(rotationProvider.notifier).state = value;
                                        }
                                      : null,
                                  max: 360,
                                  initialValue: rotation,
                                  onChange: isBluetoothConnected
                                      ? (double value) {
                                          ref.read(rotationProvider.notifier).state = value;
                                        }
                                      : null,
                                  innerWidget: (percentage) {
                                    return Center(
                                      child: Text(
                                        '${percentage.toInt()}°',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isBluetoothConnected ? Colors.black : Colors.grey,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              InkWell(
                                onTap: isBluetoothConnected
                                    ? () {
                                        final currentRotation = ref.read(rotationProvider);
                                        ref.read(rotationProvider.notifier).state = (currentRotation + 1) % 360;
                                      }
                                    : null,
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.add_circle_outline,
                                    size: 25,
                                    color: isBluetoothConnected ? Colors.black : Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            alignment: Alignment.center,
                            height: 30,
                            margin: const EdgeInsets.only(top: 10),
                            child: OutlinedButton(
                              onPressed: isBluetoothConnected
                                  ? () {
                                      ref.read(rotationProvider.notifier).state = 0.0;
                                    }
                                  : null,
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                foregroundColor: isBluetoothConnected ? Colors.black : Colors.grey,
                              ),
                              child: const Text('Açı Sıfırla'),
                            ),
                          ),
                        ],
                      ),
                      //!LAZER MAKİNESİ KONUMU
                      Column(
                        children: [
                          if (isOutOfBounds)
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Uyarı: Model çalışma alanı sınırlarını aşıyor!',
                                style: TextStyle(color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          Divider(),
                          Center(
                            child: Column(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.keyboard_arrow_up,
                                      size: 30, color: isBluetoothConnected ? Colors.blue : Colors.grey),
                                  onPressed: isBluetoothConnected
                                      ? () async {
                                          _sendGCodeCommand('G91');
                                          _sendGCodeCommand('G1 Y-2 F500');
                                          _sendGCodeCommand('G90');
                                          // Ekrandaki modeli de hareket ettir
                                          final current = ref.read(imagePositionProvider);
                                          final RenderBox? box =
                                              _containerKey.currentContext?.findRenderObject() as RenderBox?;
                                          final containerSize = box?.size ?? Size(300, 300);
                                          final maxY = containerSize.height - imageHeight;
                                          ref.read(imagePositionProvider.notifier).state =
                                              Offset(current.dx, (current.dy - step).clamp(0, maxY));
                                        }
                                      : null,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.keyboard_arrow_left,
                                          size: 30, color: isBluetoothConnected ? Colors.blue : Colors.grey),
                                      onPressed: isBluetoothConnected
                                          ? () async {
                                              _sendGCodeCommand('G91');
                                              _sendGCodeCommand('G1 X-2 F500');
                                              _sendGCodeCommand('G90');
                                              // Ekrandaki modeli de hareket ettir
                                              final current = ref.read(imagePositionProvider);
                                              final RenderBox? box =
                                                  _containerKey.currentContext?.findRenderObject() as RenderBox?;
                                              final containerSize = box?.size ?? Size(300, 300);
                                              final maxX = containerSize.width - imageWidth;
                                              ref.read(imagePositionProvider.notifier).state =
                                                  Offset((current.dx - step).clamp(0, maxX), current.dy);
                                            }
                                          : null,
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.home,
                                          size: 30, color: isBluetoothConnected ? Colors.blue : Colors.grey),
                                      onPressed: isBluetoothConnected
                                          ? () {
                                              _sendGCodeCommand("\$H");
                                              // Ekrandaki modeli de başa al
                                              ref.read(imagePositionProvider.notifier).state =
                                                  const Offset(5, 5); // veya Offset(0, 0)
                                              ref.read(rotationProvider.notifier).state = 0.0;
                                            }
                                          : null,
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.keyboard_arrow_right,
                                          size: 30, color: isBluetoothConnected ? Colors.blue : Colors.grey),
                                      onPressed: isBluetoothConnected
                                          ? () async {
                                              _sendGCodeCommand('G91');
                                              _sendGCodeCommand('G1 X2 F500');
                                              _sendGCodeCommand('G90');
                                              // Ekrandaki modeli de hareket ettir
                                              final current = ref.read(imagePositionProvider);
                                              final RenderBox? box =
                                                  _containerKey.currentContext?.findRenderObject() as RenderBox?;
                                              final containerSize = box?.size ?? Size(300, 300);
                                              final maxX = containerSize.width - imageWidth;
                                              ref.read(imagePositionProvider.notifier).state =
                                                  Offset((current.dx + step).clamp(0, maxX), current.dy);
                                            }
                                          : null,
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: Icon(Icons.keyboard_arrow_down,
                                      size: 30, color: isBluetoothConnected ? Colors.blue : Colors.grey),
                                  onPressed: isBluetoothConnected
                                      ? () async {
                                          _sendGCodeCommand('G91');
                                          _sendGCodeCommand('G1 Y2 F500');
                                          _sendGCodeCommand('G90');
                                          // Ekrandaki modeli de hareket ettir
                                          final current = ref.read(imagePositionProvider);
                                          final RenderBox? box =
                                              _containerKey.currentContext?.findRenderObject() as RenderBox?;
                                          final containerSize = box?.size ?? Size(300, 300);
                                          final maxY = containerSize.height - imageHeight;
                                          ref.read(imagePositionProvider.notifier).state =
                                              Offset(current.dx, (current.dy + step).clamp(0, maxY));
                                        }
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        alignment: Alignment.center,
                        height: 30,
                        margin: const EdgeInsets.only(bottom: 7),
                        child: ElevatedButton(
                          onPressed: isBluetoothConnected
                              ? () {
                                  pageRouteBuilder(
                                      context,
                                      MakineGcodeGonderScreen(
                                        widget.data,
                                        xKoordinat: ref.read(actualCoordinatesProvider)['x']!,
                                        yKoordinat: ref.read(actualCoordinatesProvider)['y']!,
                                        aci: ref.read(rotationProvider),
                                        gcodeId: selectedDetail.id.toString(),
                                      ));
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            backgroundColor: isBluetoothConnected ? Colors.blue : Colors.grey,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Devam Et'),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Ekran yönlendirmesini varsayılan duruma döndür
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _connectionSubscription.cancel();
    _transformationController.dispose();
    _bluetoothDataSubscription?.cancel();

    super.dispose();
  }

  void _showMessage(String message, bool isError) {
    UIHelpers.showSnackBar(
      context,
      message: message,
      isError: isError,
    );
  }

  void _toggleMirror() {
    setState(() {
      _isMirrored = !_isMirrored;
    });
  }

  Future<void> _sendGCodeCommand(String command) async {
    final controller = ref.read(bluetoothControllerProvider);

    if (controller.connection == null) {
      //_showMessage('Bluetooth bağlantısı yok!', true);

      return;
    }

    try {
      controller.connection!.output.add(Uint8List.fromList(utf8.encode('$command\n')));
      await controller.connection!.output.allSent;
      // Başarılı gönderimde mesaj gösterme!
    } catch (e) {
      _showMessage('Gönderim hatası: $e', true);
    }
  }

  Future<void> testGCode(int modelId) async {
    final dio = Dio();
    final url = 'https://kardamiyim.com/laser/API/Controller.php?endpoint=gcode/test&id=$modelId';
    try {
      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final gcode = response.data["data"];

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Gelen GCode'),
            content: SingleChildScrollView(
              child: Text(gcode),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Kapat'),
              ),
              // Gönder butonu ekleniyor
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Önce diyaloğu kapat
                  _sendGcodeToMachine(gcode); // Sonra makinaya gönder
                },
                child: const Text('Makineye Gönder'),
              ),
            ],
          ),
        );
      } else {
        print('Hata: ${response.statusCode}');
      }
    } catch (e) {
      print('İstek hatası: $e');
    }
  }

  // Gelen G-code satırlarını makineye gönderen fonksiyon
  Future<void> _sendGcodeToMachine(String gcodeText) async {
    // Bluetooth bağlantısını kontrol et
    final controller = ref.read(bluetoothControllerProvider);
    if (controller.connection == null || !controller.isConnected) {
      _showMessage('Bluetooth bağlantınız yok!', true);
      return; // Bluetooth bağlantısı yoksa işlemi sonlandır
    }

    _showMessage('G-code gönderimi başlıyor...', false);

    // İlerleme durumunu gösterecek bir diyalog göster
    showDialog(
      context: context,
      barrierDismissible: false, // Kullanıcı dışarı tıklayarak kapatamaz
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('G-Code Gönderiliyor'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LinearProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Komutlar gönderiliyor, lütfen bekleyin...'),
                ],
              ),
            );
          },
        );
      },
    );

    try {
      // Satırlara ayır
      final List<String> gcodeLines = gcodeText.split('\n');
      int total = gcodeLines.length;
      int current = 0;

      // Her bir satırı sırayla gönder
      for (String line in gcodeLines) {
        line = line.trim();
        if (line.isNotEmpty) {
          await _sendGCodeCommand(line);
          // Komutlar arasında biraz beklet (makinenin işleme zamanı için)
          await Future.delayed(const Duration(milliseconds: 300));
          current++;
        }
      }

      // İşlem tamamlandığında diyaloğu kapat
      if (mounted) {
        Navigator.of(context).pop(); // Diyaloğu kapat
        _showMessage('G-code gönderimi tamamlandı (${gcodeLines.length} komut)', false);
      }
    } catch (e) {
      // Hata durumunda diyaloğu kapat ve hata mesajı göster
      if (mounted) {
        Navigator.of(context).pop(); // Diyaloğu kapat
        _showMessage('G-code gönderimi sırasında hata: $e', true);
      }
    }
  }
}
