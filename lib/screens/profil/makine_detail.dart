import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makine/notifier/language_notifier.dart';
import 'package:makine/notifier/localization.dart';
import 'package:makine/stringKeys/string_utils.dart';

class MakineDetail extends ConsumerWidget {
  const MakineDetail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(languageProvider); // Mevcut dili al

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalization.getString(
              currentLanguage, ConstanceVariable.makineBilgi),
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            //QR gösterilecek.
            Image.asset(
              "assets/images/qrCode.png",
              width: MediaQuery.of(context).size.width / 2,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalization.getString(
                        currentLanguage, ConstanceVariable.surum),
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  //Sürüm numarası yazılacak
                  Text(
                    "V1.3210427",
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.grey),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
