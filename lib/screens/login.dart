import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makine/screens/home_page.dart';
import 'package:makine/screens/signup.dart';
import 'package:makine/utils/ui_helpers.dart';
import 'package:makine/viewmodel/custom_pageroutebuilder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../notifier/auth_notifier.dart';
import '../model/bluetooth_device_model.dart';

// Şifre görünürlük durumu için Riverpod provider
final passwordVisibilityProvider = StateProvider<bool>((ref) => false);

class Login extends ConsumerStatefulWidget {
  const Login({super.key});

  @override
  ConsumerState<Login> createState() => _LoginState();
}

class _LoginState extends ConsumerState<Login> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    ref.listen(authNotifierProvider, (previous, next) {
      next.maybeWhen(
        success: () {
          UIHelpers.showSnackBar(
            context,
            message: 'Giriş başarılı!',
            isError: false,
          ).then((_) {
            // Giriş başarılı olduğunda ana sayfaya yönlendir
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          });
        },
        error: (message) {
          UIHelpers.showSnackBar(
            context,
            message: message,
            isError: true,
          );
        },
        orElse: () {},
      );
    });

    final isPasswordVisible = ref.watch(passwordVisibilityProvider);

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/bg6.jpg"),
                  fit: BoxFit.cover, // Resmin tüm alanı kaplamasını sağlar
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      "LOGO",
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(color: Colors.white),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            child: TextFormField(
                              controller: _usernameController,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.account_circle_outlined,
                                ),
                                hintText: "Kullanıcı Adı",
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Kullanıcı adı boş olamaz';
                                }
                                return null;
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            child: TextFormField(
                              controller: _passwordController,
                              obscureText: !isPasswordVisible,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.lock_outline,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    ref.read(passwordVisibilityProvider.notifier).state = !isPasswordVisible;
                                  },
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                                hintText: "Şifre",
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Şifre boş olamaz';
                                }
                                return null;
                              },
                            ),
                          ),
                          Consumer(
                            builder: (context, ref, child) {
                              final authState = ref.watch(authNotifierProvider);

                              return authState.maybeWhen(
                                loading: () => const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                                orElse: () => ElevatedButton(
                                  onPressed: () {
                                    if (_formKey.currentState?.validate() ?? false) {
                                      ref.read(authNotifierProvider.notifier).login(
                                            _usernameController.text,
                                            _passwordController.text,
                                          );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Text(
                                    'Giriş Yap',
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () {
                              pageRouteBuilder(context, SignUp());
                            },
                            child: Text(
                              'Hesabınız yok mu? Kayıt olun',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    decoration: TextDecoration.underline,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
