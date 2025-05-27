// AppBar'daki başlık ve rengi dinamik olarak yönetmek için StateProvider
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makine/stringKeys/string_utils.dart';

final appBarTitleProvider =
    StateProvider<String>((ref) => ConstanceVariable.siniflandirma);

// Aktif olan sekmeyi takip eden StateProvider
final currentIndexProvider = StateProvider<int>((ref) => 0);
