import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makine/model/person_model.dart';
import 'package:makine/notifier/auth_notifier.dart';
import 'package:makine/notifier/language_notifier.dart';
import 'package:makine/notifier/localization.dart';
import 'package:makine/screens/bluetooth/bluetooth_scanner_screen.dart';
import 'package:makine/screens/login.dart';
import 'package:makine/screens/profil/destek_talebi.dart';
import 'package:makine/screens/profil/makine_detail.dart';
import 'package:makine/service/person_service.dart';
import 'package:makine/stringKeys/string_utils.dart';
import 'package:makine/utils/ui_helpers.dart';
import 'package:makine/viewmodel/custom_pageroutebuilder.dart';
import 'package:makine/widgets/custom_listtile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:makine/viewmodel/provider.dart';

final userDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return {
    'makineId': prefs.getString('makineId') ?? '',
    'kontor': prefs.getInt('kontor') ?? 0,
    'username': prefs.getString('username') ?? '',
  };
});

class Profil extends ConsumerStatefulWidget {
  const Profil({super.key});

  @override
  ConsumerState<Profil> createState() => _ProfilState();
}

class _ProfilState extends ConsumerState<Profil> {
  late Future<PersonModel> person;
  final PersonService _dummyPersonService = PersonService();
  // final BluetoothController _controller = BluetoothController();

  @override
  Widget build(BuildContext context) {
    final currentLanguage = ref.watch(languageProvider);
    final userData = ref.watch(userDataProvider);
    final controller = ref.watch(bluetoothControllerProvider);

    return FutureBuilder<PersonModel>(
      future: person,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          return SingleChildScrollView(
              child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 0),
                child: Column(
                  children: [
                    userData.when(
                      data: (data) => Column(
                        children: [
                          CustomListTile(
                            title: 'Kullanıcı Adı: ${data['username']}',
                            icon: Icons.person,
                          ),
                          CustomListTile(
                            title: 'Kontör: ${data['kontor']}',
                            icon: Icons.credit_card,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () {},
                                  icon: Icon(
                                    Icons.refresh,
                                    color: Colors.blue,
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => _showKontorTalepDialog(context),
                                  child: const Text('Talep Et'),
                                ),
                              ],
                            ),
                          ),
                          CustomListTile(
                            title: 'Makine ID: ${data['makineId']}',
                            icon: Icons.devices,
                          ),
                        ],
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (error, stack) => Text('Hata: $error'),
                    ),

                    CustomListTile(
                      title: AppLocalization.getString(currentLanguage, ConstanceVariable.destekTalebi),
                      icon: Icons.contact_support_outlined,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DestekTalebiScreen(),
                          ),
                        );
                      },
                    ),
                    CustomListTile(
                      title: AppLocalization.getString(currentLanguage, "Bu Makine Hakkında"),
                      icon: Icons.info_outline,
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const MakineDetail(),
                        ));
                      },
                    ),
                    // CustomListTile(
                    //   title: "Bluetooth Bağlantısı",
                    //   icon: Icons.bluetooth_audio_outlined,
                    //   onTap: () {
                    //     pageRouteBuilder(context, BluetoothScannerScreen());
                    //   },
                    // ),
                    // Bluetooth bağlantı durumu göstergesi
                    CustomListTile(
                      title: ref.watch(connectedBluetoothDeviceProvider) != null
                          ? 'Bağlı Cihaz: ${ref.watch(connectedBluetoothDeviceProvider)!.name}'
                          : 'Bluetooth Bağlantısı Yok',
                      icon: ref.watch(connectedBluetoothDeviceProvider) != null
                          ? Icons.bluetooth_connected
                          : Icons.bluetooth_disabled,
                      iconColor: ref.watch(connectedBluetoothDeviceProvider) != null ? Colors.green : Colors.red,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BluetoothScannerScreen(),
                          ),
                        );
                      },
                      trailing: ref.watch(connectedBluetoothDeviceProvider) != null
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  ref.watch(connectedBluetoothDeviceProvider)!.address.length > 8
                                      ? '${ref.watch(connectedBluetoothDeviceProvider)!.address.substring(0, 8)}...'
                                      : ref.watch(connectedBluetoothDeviceProvider)!.address,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                // IconButton(
                                //   icon: const Icon(Icons.link_off, color: Colors.red),
                                //   onPressed: () async {
                                //     // Bağlantıyı kes
                                //     final controller = ref.read(bluetoothControllerProvider);
                                //     await controller.disconnect();
                                //     // Provider'ı güncelle
                                //     ref.read(connectedBluetoothDeviceProvider.notifier).state = null;
                                //   },
                                // ),
                              ],
                            )
                          : ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const BluetoothScannerScreen(),
                                  ),
                                );
                              },
                              child: const Text('Bağlan'),
                            ),
                    ),
                    CustomListTile(
                      title: AppLocalization.getString(currentLanguage, ConstanceVariable.cikis),
                      icon: Icons.logout,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Çıkış'),
                            content: const Text('Çıkış yapmak istediğinize emin misiniz?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('İptal'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.setBool('isLoggedIn', false);
                                  pageRouteBuilder(context, Login());
                                },
                                child: const Text('Çıkış'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ));
        } else {
          return const Center(child: Text('Veri yok'));
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    person = _dummyPersonService.fetchDummyPersonData();
  }

  // void _saveProfile() {
  //   // Profil kaydetme işlemi...
  //   UIHelpers.showSnackBar(
  //     context,
  //     message: 'Profil bilgileri başarıyla güncellendi',
  //     isError: false,
  //   );
  // }

  // void _showError(String message) {
  //   UIHelpers.showSnackBar(
  //     context,
  //     message: message,
  //     isError: true,
  //   );
  // }

  // void _showIncomingMessageDialog(String message) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Gelen Mesaj'),
  //       content: Text(message),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.of(context).pop(),
  //           child: const Text('Tamam'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  void _showKontorTalepDialog(BuildContext context) {
    final kontorController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Kontör Talebi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: kontorController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Talep Edilecek Kontör Miktarı',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen bir miktar girin';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Lütfen geçerli bir sayı girin';
                    }
                    if (int.parse(value) <= 0) {
                      return 'Miktar 0\'dan büyük olmalıdır';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('İptal'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          final amount = int.parse(kontorController.text);
                          final prefs = await SharedPreferences.getInstance();
                          final userId = prefs.getString('userId') ?? '';

                          final response = await ref.read(userServiceProvider).addCredits(
                                userId: int.parse(userId),
                                amount: amount,
                              );

                          if (context.mounted) {
                            Navigator.pop(context);

                            UIHelpers.showSnackBar(
                              context,
                              message: response.success
                                  ? 'Kontör talebi başarıyla gönderildi'
                                  : response.error ?? 'Bir hata oluştu',
                              isError: !response.success,
                            );
                          }
                        }
                      },
                      child: const Text('Talep Et'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
