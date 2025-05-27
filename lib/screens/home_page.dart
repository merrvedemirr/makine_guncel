import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makine/model/bluetooth_device_model.dart';
import 'package:makine/notifier/appbar_notifier.dart';
import 'package:makine/notifier/language_notifier.dart';
import 'package:makine/notifier/localization.dart';
import 'package:makine/screens/daily_statistic.dart';
import 'package:makine/screens/month_statistic.dart';
import 'package:makine/screens/profil/profil.dart';
import 'package:makine/screens/siniflandirma.dart';
import 'package:makine/stringKeys/string_utils.dart';
import 'package:makine/viewmodel/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  //bool _autoConnectTried = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final appbarTitle = ref.watch(appBarTitleProvider);
    final index = ref.watch(currentIndexProvider);
    final currentLanguage = ref.watch(languageProvider); // Mevcut dili al

    // BottomNavigationBar'da her bir tab için gösterilecek ekranlar
    final List<Widget> pages = [
      SiniflandirmaScreen(),
      FutureBuilder<String?>(
        future: _getUserId(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final userId = snapshot.data!;
          return TabBarView(
            children: [
              DailyStatistic(userId: userId),
              MonthStatistic(userId: userId),
            ],
          );
        },
      ),
      Profil(),
    ];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: (index == 1)
            ? AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                title: TabBar(
                  dividerHeight: 0,
                  labelColor: ConstanceVariable.bottomBarSelectedColor,
                  indicatorColor: ConstanceVariable.bottomBarSelectedColor,
                  tabs: [
                    Tab(
                      text: AppLocalization.getString(currentLanguage, ConstanceVariable.dailyStatistic),
                    ),
                    Tab(text: AppLocalization.getString(currentLanguage, ConstanceVariable.monthStatistic)),
                  ],
                ),
              )
            : AppBar(
                title: Text(
                  appbarTitle,
                ),
                centerTitle: true,
                elevation: 0,
              ),
        bottomNavigationBar: _bottomNavigationBar(ref),
        body: SafeArea(
            child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 15),
          child: pages[index],
        )),
      ),
    );
  }

  Container _bottomNavigationBar(WidgetRef ref) {
    final currentLanguage = ref.watch(languageProvider); // Mevcut dili al

    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(color: Colors.grey.withOpacity(0.4), spreadRadius: 5, blurRadius: 5, offset: const Offset(0, 3))
      ]),
      child: BottomNavigationBar(
        // selectedLabelStyle: const TextStyle(fontSize: 17),
        // unselectedLabelStyle: const TextStyle(fontSize: 15),
        // type: BottomNavigationBarType.fixed,
        selectedItemColor: ConstanceVariable.bottomBarSelectedColor,
        currentIndex: ref.watch(currentIndexProvider),
        elevation: 1,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        iconSize: 30,
        showSelectedLabels: true, // ← Etiketleri göster
        showUnselectedLabels: false,
        items: <BottomNavigationBarItem>[
          //?Sınıflandırma
          BottomNavigationBarItem(
              icon: const Icon(Icons.devices),
              label: AppLocalization.getString(currentLanguage, ConstanceVariable.siniflandirma)),
          //?İstatistik
          BottomNavigationBarItem(
              icon: const Icon(Icons.insert_chart_outlined_outlined),
              label: AppLocalization.getString(currentLanguage, ConstanceVariable.istatistik)),
          //?Profil
          BottomNavigationBarItem(
              icon: const Icon(Icons.person),
              label: AppLocalization.getString(currentLanguage, ConstanceVariable.profil)),
        ],

        onTap: (index) {
          // Sekmeye tıklandığında aktif index'i güncelle
          ref.read(currentIndexProvider.notifier).state = index;
          // BottomNavigationBar tıklandığında appBar başlığını ve rengini değiştirme
          if (index == 0) {
            ref.read(appBarTitleProvider.notifier).state =
                AppLocalization.getString(currentLanguage, ConstanceVariable.siniflandirma);
          } else if (index == 1) {
            ref.read(appBarTitleProvider.notifier).state =
                AppLocalization.getString(currentLanguage, ConstanceVariable.istatistik);
          } else if (index == 2) {
            ref.read(appBarTitleProvider.notifier).state =
                AppLocalization.getString(currentLanguage, ConstanceVariable.profil);
          }
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'makineId': prefs.getString('makineId'),
      'kontor': prefs.getInt('kontor'),
      'username': prefs.getString('username'),
    };
  }

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  // Future<void> autoConnectBluetooth(WidgetRef ref) async {
  //   final controller = ref.read(bluetoothControllerProvider);
  //   if (controller.connection != null) return;

  //   final prefs = await SharedPreferences.getInstance();
  //   final lastAddress = prefs.getString('lastConnectedDeviceAddress');
  //   if (lastAddress != null) {
  //     final pairedDevices = await controller.getPairedDevices();
  //     BluetoothDeviceModel? lastDevice;
  //     try {
  //       lastDevice = pairedDevices.firstWhere((d) => d.address == lastAddress);
  //     } catch (e) {
  //       lastDevice = null;
  //     }
  //     if (lastDevice != null) {
  //       await controller.connectToDevice(lastDevice);
  //     }
  //   }
  // }
}
