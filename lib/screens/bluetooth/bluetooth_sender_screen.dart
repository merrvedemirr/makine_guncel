import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:makine/controller/bluetooth_controller.dart';
import 'package:makine/screens/home_page.dart';

class BluetoothSenderScreen extends StatefulWidget {
  final String deviceName;
  final List<String> gcodeLines;
  final int windowSize;
  final BluetoothController controller;

  const BluetoothSenderScreen({
    super.key,
    required this.deviceName,
    required this.gcodeLines,
    this.windowSize = 1,
    required this.controller,
  });

  @override
  State<BluetoothSenderScreen> createState() => _BluetoothSenderScreenState();
}

class _BluetoothSenderScreenState extends State<BluetoothSenderScreen> with WidgetsBindingObserver {
  late final BluetoothController _controller;

  bool _isComplete = false;
  double _progress = 0.0;
  bool _isSending = false;
  String? _ncContent;

  // OK yanıtı sayacı
  int _okResponseCount = 0;

  final List<String> _sentCommands = [];
  final List<String> _deviceResponses = [];
  final ScrollController _sentScrollController = ScrollController();
  final ScrollController _responseScrollController = ScrollController();

  String _deviceBuffer = '';
  StreamSubscription? _dataStreamSubscription;

  // Kuyruk için Queue oluştur
  final Queue<String> _gcodeLinesQueue = Queue<String>();
  // Mevcut paket için karakter sayacı
  int _currentPacketCharCount = 0;
  // Gönderilmeyi bekleyen satırlar
  List<String> _pendingLines = [];
  // Beklenen OK sayısı
  int _expectedOkCount = 0;
  // Mevcut paket için alınan OK sayısı
  int _currentPacketOkCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    // _initializeQueue(); // Kuyruğu başlat
    //_listenForDeviceData();
    WidgetsBinding.instance.addObserver(this);
  }

  void _initializeQueue() {
    // Tüm G-code satırlarını kuyruğa ekle
    _gcodeLinesQueue.addAll(widget.gcodeLines);
    _deviceResponses.add('🔄 G-code kuyruğu hazırlandı (${_gcodeLinesQueue.length} satır)');
  }

  Future<void> _processNextBatch() async {
    // Eğer önceki paketin tüm OK'leri gelmemişse bekle
    if (_currentPacketOkCount < _expectedOkCount || _gcodeLinesQueue.isEmpty) return;

    _pendingLines = [];
    _currentPacketCharCount = 0;
    // Yeni paket için OK sayaçlarını sıfırla
    _currentPacketOkCount = 0;
    _expectedOkCount = 0;

    // Satırları tek tek kontrol et
    while (_gcodeLinesQueue.isNotEmpty) {
      String nextLine = _gcodeLinesQueue.first;
      String cleanLine = nextLine.replaceAll('"', '');
      int lineLength = cleanLine.length + 1; // Sadece \n için +1

      if (_currentPacketCharCount + lineLength > 254) {
        break;
      }

      _gcodeLinesQueue.removeFirst();
      _pendingLines.add(cleanLine);
      _currentPacketCharCount += lineLength;
      _expectedOkCount++; // Her eklenen satır için bir OK bekliyoruz
    }

    if (_pendingLines.isNotEmpty) {
      await _sendPendingLines();
    } else if (_gcodeLinesQueue.isEmpty) {
      setState(() {
        _isComplete = true;
        _progress = 1.0;
        _isSending = false;
      });
      _deviceResponses.add('✅ Tüm G-code satırları gönderildi');

      // Bellek temizliği
      _clearMemory();

      // İşlem tamamlandıktan sonra ana sayfaya yönlendir
      // Future.delayed(const Duration(seconds: 1), () {
      //   if (mounted) {
      //     Navigator.of(context).pushAndRemoveUntil(
      //       MaterialPageRoute(builder: (context) => const HomePage()),
      //       (route) => false,
      //     );
      //   }
      // });
    }
  }

  Future<void> _sendPendingLines() async {
    try {
      String batchContent = _pendingLines.map((line) => '$line\n').join();

      _controller.connection!.output.add(Uint8List.fromList(utf8.encode(batchContent)));
      await _controller.connection!.output.allSent;

      _sentCommands.add('📤 Gönderilen paket (${_currentPacketCharCount} karakter, beklenen OK: $_expectedOkCount):');
      for (var line in _pendingLines) {
        _sentCommands.add('   $line');
      }
      _scrollToEnd(_sentScrollController);

      setState(() {
        _progress = 1 - (_gcodeLinesQueue.length / widget.gcodeLines.length);
      });
    } catch (e) {
      _deviceResponses.add('❌ Gönderim hatası: $e');
      _scrollToEnd(_responseScrollController);
    }
  }

  void _listenForDeviceData() {
    final stream = _controller.getDataStream();
    if (stream == null) return;

    _dataStreamSubscription = stream.listen(
      (data) {
        _deviceBuffer += data;
        if (_deviceBuffer.contains('\n')) {
          var lines = _deviceBuffer.split('\n');
          _deviceBuffer = lines.removeLast();

          for (var line in lines) {
            line = line.trim();
            if (line.isNotEmpty) {
              if (line.toLowerCase().contains('ok')) {
                setState(() {
                  _okResponseCount++;
                  _currentPacketOkCount++;
                });
                _deviceResponses.add('📥 Alındı: $line (Paket OK: $_currentPacketOkCount/$_expectedOkCount)');

                // Eğer bu paketteki tüm OK'ler geldiyse yeni paketi işle
                if (_currentPacketOkCount >= _expectedOkCount) {
                  _processNextBatch();
                }
              } else {
                _deviceResponses.add('📥 Alındı: $line');
              }
            }
          }
          _scrollToEnd(_responseScrollController);
        }
      },
      onError: (error) {
        _deviceResponses.add('❌ Veri akışı hatası: $error');
        _scrollToEnd(_responseScrollController);
      },
      onDone: () {
        _deviceResponses.add('⚡ Bağlantı kapandı');
        _scrollToEnd(_responseScrollController);
      },
    );
  }

  void _startSending() {
    if (_isSending) return;

    setState(() {
      _isSending = true;
      _okResponseCount = 0;
      _currentPacketOkCount = 0;
      _expectedOkCount = 0;
    });

    _showSendingDialog();
    _initializeQueue(); // Kuyruğu başlat
    _listenForDeviceData();

    _processNextBatch();
  }

  void _showSendingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              // İşlem tamamlandıysa diyaloğu kapat ve ana sayfaya yönlendir
              if (_isComplete) {
                // Kısa bir gecikme sonrası diyaloğu kapat
                Future.delayed(const Duration(seconds: 1), () {
                  if (mounted && Navigator.of(context).canPop()) {
                    Navigator.of(context).pop(); // Diyaloğu kapat

                    // Ana sayfaya yönlendir
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const HomePage()),
                      (route) => false,
                    );
                  }
                });
              }

              return AlertDialog(
                title: const Text('Gönderim Devam Ediyor'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(value: _progress),
                    const SizedBox(height: 16),
                    Text(_isSending ? '%${(_progress * 100).toStringAsFixed(0)} tamamlandı' : 'İptal Edildi'),

                    // İşlem tamamlandığında gösterilecek metin
                    if (_isComplete) ...[
                      const SizedBox(height: 16),
                      const Text(
                        '✅ Gönderim tamamlandı!',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ],
                ),
                actions: [
                  // Sadece işlem devam ediyorsa İptal Et butonu göster
                  if (!_isComplete)
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          // Önce M5 komutunu gönder ve yanıtı bekle
                          _controller.connection!.output.add(Uint8List.fromList(utf8.encode("M5\n")));
                          await _controller.connection!.output.allSent;
                          _deviceResponses.add('⚠️ M5 komutu gönderildi');
                          await Future.delayed(const Duration(milliseconds: 500)); // Yanıt için bekle

                          // Sonra $H komutunu gönder ve yanıtı bekle
                          _controller.connection!.output.add(Uint8List.fromList(utf8.encode("\$H\n")));
                          await _controller.connection!.output.allSent;
                          _deviceResponses.add('⚠️ \$H komutu gönderildi');
                          await Future.delayed(const Duration(milliseconds: 500)); // Yanıt için bekle
                        } catch (e) {
                          _deviceResponses.add('❌ Acil durum komutları gönderilemedi: $e');
                        }

                        // Gönderimi durdur
                        _gcodeLinesQueue.clear(); // Kalan komutları temizle
                        _pendingLines.clear(); // Bekleyen komutları temizle
                        setDialogState(() {
                          _isSending = false;
                        });

                        // İptal mesajını göster
                        _deviceResponses.add('⚠️ Gönderim kullanıcı tarafından iptal edildi');
                        _scrollToEnd(_responseScrollController);

                        // Kısa bir gecikme ekle ve diyaloğu kapat
                        await Future.delayed(const Duration(milliseconds: 500));
                        if (mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('Gönderimi İptal Et'),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _scrollToEnd(ScrollController controller) {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (controller.hasClients) {
        controller.animateTo(
          controller.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _dataStreamSubscription?.cancel();
    _sentScrollController.dispose();
    _responseScrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    //_controller.disconnect();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      _controller.disconnect();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dosya Gönderimi: ${widget.deviceName}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // NC dosya bilgisi
            if (_ncContent != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.file_present, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          'Dosya Hazır',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Boyut: ${_ncContent!.length} byte',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            LinearProgressIndicator(
              value: _progress,
              minHeight: 10,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (!_isSending && !_isComplete)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _startSending,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      ),
                      child: const Text(
                        'Gönder',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                const SizedBox(width: 10),
                // OK sayacını gösteren bilgi kartı
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'OK Sayısı: $_okResponseCount',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_isComplete)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  '✅ Gönderim tamamlandı!',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _buildLogSection('Gönderilen Komutlar', _sentCommands, _sentScrollController),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildLogSection('Cihazdan Gelen Yanıtlar', _deviceResponses, _responseScrollController),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogSection(String title, List<String> messages, ScrollController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(color: Colors.white24),
          Expanded(
            child: ListView.builder(
              controller: controller,
              padding: const EdgeInsets.all(8),
              itemCount: messages.length,
              itemBuilder: (context, index) => Text(
                messages[index],
                style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Bellek temizliği için yeni metod
  void _clearMemory() {
    // Büyük veri yapılarını temizle
    _sentCommands.clear();
    _deviceResponses.clear();
    _pendingLines.clear();
    _gcodeLinesQueue.clear();

    // Gereksiz büyük nesneleri null'a çevir
    _ncContent = null;

    // Veri akışını iptal et ve yeniden bağlı olup olmadığını kontrol et
    if (_dataStreamSubscription != null) {
      _dataStreamSubscription!.cancel();
      _listenForDeviceData(); // Gerekirse yeniden bağlan
    }

    // Zorunlu çöp toplama tavsiyesi
    // (Not: Bu garanti edilmez ama tavsiye niteliğindedir)
    // ignore: unnecessary_statements
    const Duration(seconds: 1);
  }
}
