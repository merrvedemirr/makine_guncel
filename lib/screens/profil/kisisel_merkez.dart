import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makine/model/person_model.dart';
import 'package:makine/notifier/language_notifier.dart';
import 'package:makine/notifier/localization.dart';
import 'package:makine/service/person_service.dart';
import 'package:makine/stringKeys/string_utils.dart';
import 'package:makine/widgets/custom_listtile.dart';

class KisiselMerkez extends ConsumerStatefulWidget {
  const KisiselMerkez({super.key});

  @override
  ConsumerState<KisiselMerkez> createState() => _KisiselMerkezState();
}

class _KisiselMerkezState extends ConsumerState<KisiselMerkez> {
  late Future<PersonModel> person;
  final PersonService _dummyPersonService =
      PersonService(); // Dummy service instance

  @override
  void initState() {
    super.initState();
    // Dummy servisten veri çekiyoruz
    person = _dummyPersonService.fetchDummyPersonData();
  }

  @override
  Widget build(BuildContext context) {
    final currentLanguage = ref.watch(languageProvider); // Mevcut dili al

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            AppLocalization.getString(
                currentLanguage, ConstanceVariable.kisiselVeri),
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        body: FutureBuilder<PersonModel>(
          future: person,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Text('Hata: ${snapshot.error}');
            } else if (snapshot.hasData) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  elevation: 9,
                  shadowColor: Colors.grey,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomListTile(
                          isRedirect: true,
                          kisiselVeri: snapshot.data?.kullaniciAdi,
                          isKisiselVeri: true,
                          title: AppLocalization.getString(
                              currentLanguage, ConstanceVariable.kullaniciAdi),
                          icon: Icons.person_pin_outlined,
                        ),
                        CustomListTile(
                          isRedirect: true,
                          kisiselVeri: snapshot.data?.isim,
                          isKisiselVeri: true,
                          title: AppLocalization.getString(
                              currentLanguage, ConstanceVariable.isim),
                          icon: Icons.person_pin_outlined,
                        ),
                        CustomListTile(
                          isRedirect: true,
                          kisiselVeri: snapshot.data?.telNo,
                          isKisiselVeri: true,
                          title: AppLocalization.getString(
                              currentLanguage, ConstanceVariable.cepTel),
                          icon: Icons.phone,
                        ),
                        CustomListTile(
                          isRedirect: true,
                          kisiselVeri: snapshot.data?.mail,
                          isKisiselVeri: true,
                          title: AppLocalization.getString(
                              currentLanguage, ConstanceVariable.ePosta),
                          icon: Icons.mail_outline_outlined,
                        ),
                        CustomListTile(
                          isRedirect: true,
                          kisiselVeri: snapshot.data?.adress,
                          isKisiselVeri: true,
                          title: AppLocalization.getString(
                              currentLanguage, ConstanceVariable.adres),
                          icon: Icons.location_on_outlined,
                        ),
                        // CustomListTile(
                        //   title: AppLocalization.getString(currentLanguage, ConstanceVariable.kullaniciAdi),
                        //   icon: Icons.ac_unit_outlined,
                        //   size: 15,
                        //   iconColor: Colors.red,
                        //   isKisiselVeri: true,
                        //   kisiselVeri: snapshot.data?.kullaniciAdi,
                        //   isRedirect: true,
                        // ),
                        // CustomListTile(
                        //   title: AppLocalization.getString(currentLanguage, ConstanceVariable.isim),
                        //   icon: Icons.ac_unit_outlined,
                        //   size: 15,
                        //   iconColor: Colors.red,
                        //   isKisiselVeri: true,
                        //   kisiselVeri: snapshot.data?.isim,
                        //   isRedirect: true,
                        // ),
                        // CustomListTile(
                        //   title: AppLocalization.getString(currentLanguage, ConstanceVariable.cepTel),
                        //   icon: Icons.ac_unit_outlined,
                        //   size: 15,
                        //   iconColor: Colors.red,
                        //   isKisiselVeri: true,
                        //   kisiselVeri: snapshot.data?.telNo,
                        //   isRedirect: true,
                        // ),
                        // CustomListTile(
                        //   title: AppLocalization.getString(currentLanguage, ConstanceVariable.ePosta),
                        //   icon: Icons.ac_unit_outlined,
                        //   size: 15,
                        //   iconColor: Colors.red,
                        //   isKisiselVeri: true,
                        //   kisiselVeri: snapshot.data?.mail,
                        //   isRedirect: true,
                        // ),
                        // CustomListTile(
                        //   title: AppLocalization.getString(currentLanguage, ConstanceVariable.adres),
                        //   icon: Icons.ac_unit_outlined,
                        //   size: 15,
                        //   iconColor: Colors.red,
                        //   isKisiselVeri: true,
                        //   kisiselVeri: snapshot.data?.adress,
                        //   isRedirect: true,
                        // ),
                      ],
                    ),
                  ),
                ),
              );
            } else {
              return const Center(child: Text('Kullanıcı verisi yok'));
            }
          },
        ),
      ),
    );
  }
}
