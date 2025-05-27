import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makine/notifier/language_notifier.dart';
import 'package:makine/notifier/localization.dart';
import 'package:makine/stringKeys/string_utils.dart';

class DilAyarlarScreen extends ConsumerWidget {
  const DilAyarlarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(languageProvider); // Mevcut dili al

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalization.getString(
            currentLanguage, ConstanceVariable.dilAyarla)),
      ),
      body: Column(
        children: [
          ListTile(
            title: const Text('Türkçe'),
            onTap: () {
              ref
                  .read(languageProvider.notifier)
                  .changeLanguage(AppLanguage.turkish);
            },
          ),
          ListTile(
            title: const Text('English'),
            onTap: () {
              ref
                  .read(languageProvider.notifier)
                  .changeLanguage(AppLanguage.english);
            },
          ),
        ],
      ),
    );
  }
}
