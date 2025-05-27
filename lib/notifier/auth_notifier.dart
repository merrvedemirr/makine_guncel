import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../service/user_service.dart';
import '../state/auth_state.dart';

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final userService = ref.watch(userServiceProvider);
  return AuthNotifier(userService);
});

final userServiceProvider = Provider((ref) => UserService());

class AuthNotifier extends StateNotifier<AuthState> {
  final UserService _userService;

  AuthNotifier(this._userService) : super(const AuthState.initial());

  Future<void> login(String username, String password) async {
    state = const AuthState.loading();

    final response = await _userService.login(username, password);

    if (response.success && response.data != null) {
      final userData = response.data!;

      // Kullanıcı verilerini SharedPreferences'a kaydet
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('makineId', userData['makineId'].toString());
      await prefs.setInt('kontor', userData['kontor']);
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userId', userData['userId'].toString());
      await prefs.setString('username', userData['username'].toString());

      state = const AuthState.success();
    } else {
      state = AuthState.error(response.error ?? 'Giriş başarısız');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Tüm verileri temizle
    state = const AuthState.initial();
  }

  Future<void> signup({
    required String username,
    required String firstName,
    required String lastName,
    required String password,
    required String email,
    required String phone,
    required String machineUuid,
  }) async {
    state = const AuthState.loading();

    final response = await _userService.register(
      username: username,
      firstName: firstName,
      lastName: lastName,
      password: password,
      email: email,
      phone: phone,
      machineUuid: machineUuid,
    );

    if (response.success) {
      // Başarılı kayıt sonrası bilgileri SharedPreferences'a kaydet
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('username', username);
      await prefs.setString('makineId', machineUuid);
      // API'den gelen kontör değeri varsa onu da kaydedelim
      if (response.data?['kontor'] != null) {
        await prefs.setInt('kontor', response.data!['kontor']);
      }
      state = const AuthState.success();
    } else {
      state = AuthState.error(response.error ?? 'Bilinmeyen bir hata oluştu');
    }
  }
}
