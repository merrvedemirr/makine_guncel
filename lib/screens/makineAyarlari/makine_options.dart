import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:makine/screens/makineAyarlari/cron_jobs_loading.dart';
import 'package:makine/service/komut_service.dart';
import 'package:makine/utils/ui_helpers.dart';

// Lazer ayarları için model sınıfı
class LazerAyar {
  final String id;
  final String ayarAdi;
  final String lazerHizi;
  final String lazerGucu;
  final String createdAt;
  final String status;

  LazerAyar({
    required this.id,
    required this.ayarAdi,
    required this.lazerHizi,
    required this.lazerGucu,
    required this.createdAt,
    required this.status,
  });

  factory LazerAyar.fromJson(Map<String, dynamic> json) {
    return LazerAyar(
      id: json['id'] ?? '',
      ayarAdi: json['ayar_adi'] ?? '',
      lazerHizi: json['lazer_hizi'] ?? '',
      lazerGucu: json['lazer_gucu'] ?? '',
      createdAt: json['created_at'] ?? '',
      status: json['status'] ?? '',
    );
  }
}

class MakineOptionsScreen extends StatefulWidget {
  final double xKoordinat;
  final double yKoordinat;
  final double aci;
  final String gcodeId;

  const MakineOptionsScreen({
    super.key,
    required this.xKoordinat,
    required this.yKoordinat,
    required this.aci,
    required this.gcodeId,
  });

  @override
  State<MakineOptionsScreen> createState() => _MakineOptionsScreenState();
}

class _MakineOptionsScreenState extends State<MakineOptionsScreen>
    with TickerProviderStateMixin {
  int lazerHizi = 50;
  int lazerGucu = 50;
  bool isLoading = false;
  bool isLoadingAyarlar = true;
  final GCodeService _gCodeService = GCodeService(Dio());
  final Dio _dio = Dio();
  late TabController tabController;
  int selectedIndex = 0;
  List<LazerAyar> ayarlar = [];
  LazerAyar? selectedAyar;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Makine Ayarları'),
          bottom: TabBar(
            controller: tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.black,
            labelStyle:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            indicator: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.only(
                topLeft: selectedIndex != 0
                    ? Radius.circular(5)
                    : Radius.circular(0),
                topRight: selectedIndex == 0
                    ? Radius.circular(5)
                    : Radius.circular(0),
              ),
            ),
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Varsayılan'),
              Tab(text: 'Özel'),
            ],
          ),
        ),
        body: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: TabBarView(
                  controller: tabController,
                  children: [
                    // Varsayılan ayarlar sekmesi
                    Container(
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          isLoadingAyarlar
                              ? const Center(child: CircularProgressIndicator())
                              : ayarlar.isEmpty
                                  ? const Center(
                                      child: Text('Kayıtlı ayar bulunamadı'),
                                    )
                                  : DropdownButtonFormField<LazerAyar>(
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        labelText: 'Ayar Seçin',
                                      ),
                                      value: selectedAyar,
                                      items: ayarlar.map((LazerAyar ayar) {
                                        return DropdownMenuItem<LazerAyar>(
                                          value: ayar,
                                          child: Text(ayar.ayarAdi),
                                        );
                                      }).toList(),
                                      onChanged: (LazerAyar? value) {
                                        setState(() {
                                          selectedAyar = value;
                                          if (value != null) {
                                            // Seçilen ayarın değerlerini güncelle
                                            lazerHizi =
                                                int.tryParse(value.lazerHizi) ??
                                                    50;
                                            lazerGucu =
                                                int.tryParse(value.lazerGucu) ??
                                                    50;
                                          }
                                        });
                                      },
                                    ),
                          if (selectedAyar != null) ...[
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Ayar Adı: ${selectedAyar!.ayarAdi}'),
                                    const SizedBox(height: 8),
                                    Text(
                                        'Lazer Hızı: ${selectedAyar!.lazerHizi}'),
                                    const SizedBox(height: 8),
                                    Text(
                                        'Lazer Gücü: ${selectedAyar!.lazerGucu}'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Özel ayarlar sekmesi
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          const Text('Lazer Hızı'),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text('0'),
                              Expanded(
                                child: Slider(
                                  value: lazerHizi.toDouble(),
                                  min: 0,
                                  max: 100,
                                  divisions: 100,
                                  label: lazerHizi.toString(),
                                  onChanged: (double value) {
                                    setState(() {
                                      lazerHizi = value.toInt();
                                    });
                                  },
                                ),
                              ),
                              Text('100'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text('Lazer Gücü'),
                          Row(
                            children: [
                              Text('0'),
                              Expanded(
                                child: Slider(
                                  value: lazerGucu.toDouble(),
                                  min: 0,
                                  max: 100,
                                  divisions: 100,
                                  label: lazerGucu.toString(),
                                  onChanged: (double value) {
                                    setState(() {
                                      lazerGucu = value.toInt();
                                    });
                                  },
                                ),
                              ),
                              Text('100'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isLoading ? null : _sendLazerKesimData,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Devam Et'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(() {
      setState(() {
        selectedIndex = tabController.index;
      });
    });

    // API'den ayarları yükle
    _fetchLazerAyarlar();
  }

  // API'den lazer ayarlarını getir
  Future<void> _fetchLazerAyarlar() async {
    setState(() {
      isLoadingAyarlar = true;
    });

    try {
      final response = await _dio.get(
        'https://kardamiyim.com/laser/API/Controller.php?endpoint=ayar/get',
        options: Options(
          validateStatus: (status) => true,
        ),
      );
      print(response.data);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        setState(() {
          ayarlar = data.map((item) => LazerAyar.fromJson(item)).toList();
          isLoadingAyarlar = false;

          // Eğer ayar varsa ilk ayarı seç
          if (ayarlar.isNotEmpty) {
            selectedAyar = ayarlar.first;
            lazerHizi = int.tryParse(selectedAyar!.lazerHizi) ?? 50;
            lazerGucu = int.tryParse(selectedAyar!.lazerGucu) ?? 50;
          }
        });
      } else {
        _showErrorMessage('Ayarlar yüklenemedi: ${response.statusCode}');
        setState(() {
          isLoadingAyarlar = false;
        });
      }
    } catch (e) {
      _showErrorMessage('Ayarlar yüklenirken hata: $e');
      setState(() {
        isLoadingAyarlar = false;
      });
    }
  }

  Future<void> _sendLazerKesimData() async {
    // İşlem gecikmesi için dialog göster
    _showDelaySettingDialog();
  }

  // İsteği gönder ve sayfaya yönlendir
  Future<void> _sendRequest(int delayMs) async {
    setState(() {
      isLoading = true;
    });

    try {
      if (selectedIndex == 0) {
        lazerHizi = int.tryParse(selectedAyar!.lazerHizi) ?? 50;
        lazerGucu = int.tryParse(selectedAyar!.lazerGucu) ?? 50;
      }

      final result = await _gCodeService.sendLazerKesimData(
        gcodeId: widget.gcodeId,
        lazerHiz: lazerHizi.toString(),
        lazerGucu: lazerGucu.toString(),
        aci: widget.aci.toString(),
        x: widget.xKoordinat.toString(),
        y: widget.yKoordinat.toString(),
        kontor: '1', // Varsayılan değer
      );

      if (result.success) {
        _showSuccessMessage('Lazer kesim bilgileri başarıyla kaydedildi');

        // CronJobsLoading sayfasına yönlendir
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => CronJobsLoading(delayMs: delayMs),
          ),
          (route) => false,
        );
      } else {
        // API'den gelen hata mesajını göster
        _showErrorMessage(
            result.errorMessage ?? 'Lazer kesim bilgileri kaydedilemedi');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      _showErrorMessage('Hata: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // İşlem gecikmesi için dialog
  void _showDelaySettingDialog() {
    int delayMs = 100; // Varsayılan değer

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('İşlem Gecikmesi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'GCode işlemleri arasındaki gecikme süresini milisaniye cinsinden belirleyin:'),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: delayMs.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Gecikme (ms)',
                  border: OutlineInputBorder(),
                  suffixText: 'ms',
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    delayMs = int.parse(value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dialog'u kapat
                _sendRequest(delayMs); // Seçilen değerle isteği gönder
              },
              child: const Text('Devam Et'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorMessage(String message) {
    UIHelpers.showSnackBar(
      context,
      message: message,
      isError: true,
    );
  }

  void _showSuccessMessage(String message) {
    UIHelpers.showSnackBar(
      context,
      message: message,
      isError: false,
    );
  }
}
