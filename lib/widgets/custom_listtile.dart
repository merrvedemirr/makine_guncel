import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makine/notifier/language_notifier.dart';
import 'package:makine/notifier/localization.dart';
import 'package:makine/stringKeys/string_utils.dart';

class CustomListTile extends ConsumerWidget {
  final String title;
  final bool isBluetooth;
  final IconData icon;
  final void Function()? onTap;
  final Color iconColor;
  final double size;
  final bool isKisiselVeri;
  final String? kisiselVeri;
  final bool isRedirect;
  final Widget? trailing;
  const CustomListTile({
    super.key,
    required this.title,
    this.iconColor = ConstanceVariable.bottomBarSelectedColor,
    this.isBluetooth = false,
    this.isKisiselVeri = false,
    required this.icon,
    this.size = 30,
    this.onTap,
    this.kisiselVeri,
    this.isRedirect = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(languageProvider); // Mevcut dili al

    return Column(
      children: [
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
          onTap: onTap,
          leading: Icon(
            icon,
            size: size,
            color: iconColor,
          ),
          title: Text(title),
          subtitle: isRedirect
              ? Text(
                  kisiselVeri ?? "",
                  maxLines: 3, // Tek satırda gösterecek
                  overflow:
                      TextOverflow.ellipsis, // Satır taşarsa "..." gösterecek
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                )
              : null,
          trailing: trailing ??
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  isBluetooth
                      ? Text(
                          AppLocalization.getString(
                              currentLanguage, ConstanceVariable.baglandi),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: Colors.grey),
                        )
                      : const SizedBox.shrink(),
                  isRedirect
                      ? SizedBox.shrink()
                      : Icon(
                          Icons.chevron_right_outlined,
                          color: Colors.grey,
                        ),
                ],
              ),
        ),
        isRedirect
            ? SizedBox.shrink()
            : Divider(
                color: Colors.grey.shade300,
                thickness: 1,
                height: 0,
              )
      ],
    );
  }
}
