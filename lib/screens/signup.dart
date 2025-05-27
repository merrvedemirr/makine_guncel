import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makine/components/intl_phone_field.dart';
import 'package:makine/utils/is_valid.dart';
import 'package:makine/utils/ui_helpers.dart';

import '../notifier/auth_notifier.dart';

final confirmPasswordVisibilityProvider = StateProvider<bool>((ref) => false);
// Şifre görünürlük durumu için Riverpod provider
final passwordVisibilityProvider = StateProvider<bool>((ref) => false);

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Handle the input formatting here
    // Remove any spaces from the input value
    String newText = newValue.text.replaceAll(' ', '');

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class SignUp extends ConsumerStatefulWidget {
  const SignUp({super.key});

  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends ConsumerState<SignUp> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _machineUuidController = TextEditingController();

  bool check = false;
  bool error = false;
  String dialCode = "";

  String countryCode = WidgetsBinding.instance.window.locale.countryCode ?? 'tr';
  @override
  Widget build(BuildContext context) {
    ref.listen(authNotifierProvider, (previous, next) {
      next.maybeWhen(
        success: () {
          UIHelpers.showSnackBar(
            context,
            message: 'Kayıt başarılı! Giriş yapabilirsiniz.',
            isError: false,
          ).then((_) {
            Navigator.pop(context);
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
    final isConfirmPasswordVisible = ref.watch(confirmPasswordVisibilityProvider);

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
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 0),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20, top: 40),
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
                            _buildTextField(
                              controller: _usernameController,
                              labelText: "Kullanıcı Adı",
                              icon: Icons.person_outline,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Kullanıcı adı boş olamaz';
                                }
                                return null;
                              },
                            ),
                            _buildTextField(
                              controller: _firstNameController,
                              labelText: "Ad",
                              icon: Icons.person_outline,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ad boş olamaz';
                                }
                                return null;
                              },
                            ),
                            _buildTextField(
                              controller: _lastNameController,
                              labelText: "Soyad",
                              icon: Icons.person_outline,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Soyad boş olamaz';
                                }
                                return null;
                              },
                            ),
                            _buildTextField(
                              controller: _emailController,
                              labelText: "E-posta",
                              icon: Icons.email_outlined,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'E-posta boş olamaz';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                  return 'Geçerli bir e-posta adresi giriniz';
                                }
                                return null;
                              },
                            ),
                            _buildTextField(
                                controller: _machineUuidController,
                                labelText: "Makine UUID",
                                icon: Icons.numbers_outlined,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Makine UUID boş olamaz';
                                  }
                                  return null;
                                },
                                keyboardType: TextInputType.number,
                                isSerialNumber: true),
                            IntlPhoneField(
                              showCountryFlag: true,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.left,
                              onCountryChanged: ((value) {
                                dialCode = value.countryCode!;
                                countryCode = value.countryISOCode!;
                              }),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Telefon boş olamaz';
                                }
                                return null;
                              },
                              onChanged: ((value) async {
                                bool isValid = IsValid.validatePhoneNumber(
                                    countryCode: countryCodeFromString(value.countryISOCode!)!,
                                    phoneNumber: value.completeNumber);

                                if (isValid) {
                                  setState(() {
                                    check = true;
                                    error = false;
                                  });
                                } else {
                                  setState(() {
                                    check = false;
                                    error = true;
                                  });
                                }
                              }),
                              dropdownDecoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              controller: _phoneController,
                              initialCountryCode: countryCode,
                              countryCodeTextColor: Colors.grey,
                              showDropdownIcon: false,

                              // dropdownTextStyle: Styles.getStyle(
                              //     Colors.white, 11.sp, FontWeight.normal),
                              dropDownIcon: const Icon(
                                Icons.phone,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(15), // Limit the length if needed
                                PhoneNumberFormatter(), // Custom formatter to remove spaces
                              ],

                              decoration: InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 0),
                                  suffixIcon: error
                                      ? Icon(
                                          Icons.error,
                                          color: Colors.red,
                                        )
                                      : SizedBox(
                                          width: 0,
                                          height: 0,
                                        ),
                                  filled: true,
                                  hintText: "Telefon Numarası"),
                            ),
                            _buildPasswordField(
                              controller: _passwordController,
                              labelText: "Şifre",
                              isVisible: isPasswordVisible,
                              onVisibilityChanged: () {
                                ref.read(passwordVisibilityProvider.notifier).state = !isPasswordVisible;
                              },
                            ),
                            const SizedBox(height: 20),
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
                                        ref.read(authNotifierProvider.notifier).signup(
                                              username: _usernameController.text,
                                              firstName: _firstNameController.text,
                                              lastName: _lastNameController.text,
                                              password: _passwordController.text,
                                              email: _emailController.text,
                                              phone: _phoneController.text,
                                              machineUuid: _machineUuidController.text,
                                            );
                                      }
                                    },
                                    child: Text(
                                      'Kayıt Ol',
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(
                                'Zaten hesabınız var mı? Giriş yapın',
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
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _machineUuidController.dispose();
    super.dispose();
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String labelText,
    required bool isVisible,
    required VoidCallback onVisibilityChanged,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: !isVisible,
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.lock_outline,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              isVisible ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: onVisibilityChanged,
          ),
          hintText: labelText,
        ),
        validator: validator ??
            (value) {
              if (value == null || value.isEmpty) {
                return 'Şifre boş olamaz';
              }
              return null;
            },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    String? Function(String?)? validator,
    bool isSerialNumber = false,
    TextInputType? keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: isSerialNumber
            ? [
                TextInputFormatter.withFunction((oldValue, newValue) {
                  final text = newValue.text.toUpperCase();
                  if (text.length > 19) return oldValue;

                  String formatted = '';
                  String raw = text.replaceAll('-', '');

                  for (int i = 0; i < raw.length; i++) {
                    if (i > 0 && i % 4 == 0 && formatted.length < 19) {
                      formatted += '-';
                    }
                    formatted += raw[i];
                  }

                  return TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(offset: formatted.length),
                  );
                })
              ]
            : null,
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
          hintText: labelText,
        ),
        validator: validator,
      ),
    );
  }
}
