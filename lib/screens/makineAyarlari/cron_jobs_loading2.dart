import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:makine/logger.dart';
import 'package:makine/screens/home_page.dart';
import 'package:makine/utils/ui_helpers.dart';

class CronJobsLoading2 extends StatefulWidget {
  final int delayMs;

  const CronJobsLoading2({
    super.key,
    this.delayMs = 100, // Varsayılan değer 100ms
  });

  @override
  State<CronJobsLoading2> createState() => _CronJobsLoading2State();
}

class _CronJobsLoading2State extends State<CronJobsLoading2>
    with SingleTickerProviderStateMixin {
  final Dio _dio = Dio();
  bool isLoading = true;
  String statusMessage = "GCode dosyaları hazırlanıyor...";
  double progress = 0.0;
  int totalUrls = 0;
  int processedUrls = 0;
  late AnimationController _animationController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GCode İşleme'),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isLoading) ...[
                      // Yükleme durumu
                      SizedBox(
                        height: 100,
                        width: 100,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Dönen animasyon
                            // RotationTransition(
                            //   turns: _animationController,
                            //   child: CircularProgressIndicator(
                            //     value: progress > 0 ? null : 1.0,
                            //     strokeWidth: 3,
                            //     color: Theme.of(context)
                            //         .colorScheme
                            //         .primary
                            //         .withOpacity(0.5),
                            //   ),
                            // ),
                            // // İlerleme göstergesi

                            SizedBox(
                              width: 70,
                              height: 70,
                              child: CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 6,
                                  backgroundColor: Colors.blue.shade100,
                                  color: Colors.blue),
                            ),

                            // İlerleme yüzdesi
                            if (progress > 0)
                              Text(
                                "${(progress * 100).toInt()}%",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        statusMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (totalUrls > 0) ...[
                        const SizedBox(height: 24),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey.shade100,
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "İşlenen Dosyalar:",
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    "$processedUrls / $totalUrls",
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 10,
                                  backgroundColor: Colors.grey.shade300,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.blue),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ] else ...[
                      // İşlem tamamlandı veya hata durumu
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          color: statusMessage.contains("başarıyla")
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          statusMessage.contains("başarıyla")
                              ? Icons.check_circle_outline
                              : Icons.error_outline,
                          size: 70,
                          color: statusMessage.contains("başarıyla")
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        statusMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: statusMessage.contains("başarıyla")
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (context) => const HomePage()),
                            (route) => false,
                          );
                        },
                        icon: const Icon(Icons.home, color: Colors.white),
                        label: const Text('Ana Sayfaya Dön',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _fetchAndProcessGCodes();
  }

  Future<void> _fetchAndProcessGCodes() async {
    try {
      setState(() {
        isLoading = true;
        statusMessage = "GCode URL'leri alınıyor...";
      });

      // API'den GCode URL'lerini al
      final response = await _dio.get(
        "https://kardamiyim.com/laser/API/Controller.php?endpoint=cron/generateGCodes",
        options: Options(
          validateStatus: (status) => true,
        ),
      );

      logger.i("GCode URL yanıtı: ${response.data}");

      if (response.statusCode == 200 &&
          response.data is Map &&
          response.data.containsKey('cmd')) {
        final List<dynamic> urls = response.data['cmd'];
        logger.i("GCode URL'leri: $urls");
        totalUrls = urls.length;

        if (totalUrls == 0) {
          setState(() {
            isLoading = false;
            statusMessage = "İşlenecek GCode URL'si bulunamadı";
          });
          _showMessage("İşlenecek GCode URL'si bulunamadı");
          _navigateToHome();
          return;
        }

        setState(() {
          statusMessage = "GCode dosyaları işleniyor (0/$totalUrls)";
        });

        // Her URL'yi sırayla işle
        for (int i = 0; i < urls.length; i++) {
          final url = urls[i];

          // URL'ye istek at
          await _processUrl(url);

          // İlerleme durumunu güncelle
          processedUrls = i + 1;
          setState(() {
            progress = processedUrls / totalUrls;
            statusMessage =
                "GCode dosyaları işleniyor ($processedUrls/$totalUrls)";
          });

          // Kullanıcının belirlediği süre kadar bekle
          await Future.delayed(Duration(milliseconds: widget.delayMs));
        }

        // Tüm işlemler tamamlandı
        setState(() {
          isLoading = false;
          statusMessage = "Tüm GCode dosyaları başarıyla işlendi!";
        });

        _showMessage("Tüm GCode dosyaları başarıyla işlendi!");

        // Ana sayfaya yönlendir
        _navigateToHome();
      } else {
        setState(() {
          isLoading = false;
          statusMessage = "GCode URL'leri alınamadı: ${response.statusCode}";
        });
        _showMessage("GCode URL'leri alınamadı: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        statusMessage = "Hata: $e";
      });
      _showMessage("Hata: $e");
    }
  }

  void _navigateToHome() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      }
    });
  }

  Future<void> _processUrl(String url) async {
    try {
      final response = await _dio.get(
        url,
        options: Options(
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode != 200) {
        logger.e("URL işleme hatası: $url - ${response.statusCode}");
      }
    } catch (e) {
      logger.e("URL işleme hatası: $url - $e");
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      UIHelpers.showSnackBar(
        context,
        message: message,
        isError: !message.contains("başarıyla"),
      );
    }
  }
}
