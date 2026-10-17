import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  static const String savedEmailKey = '999_signal_saved_email';
  static const String savedPasswordKey = '999_signal_saved_password';

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  String? errorMessage;

  Future<void> signIn() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final email = emailController.text.trim();
      final password = passwordController.text;

      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      await secureStorage.write(
        key: savedEmailKey,
        value: email,
      );

      await secureStorage.write(
        key: savedPasswordKey,
        value: password,
      );
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => errorMessage = e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => errorMessage = 'Login failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> signInWithFaceId() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final auth = LocalAuthentication();

      final canCheckBiometrics = await auth.canCheckBiometrics;
      final isDeviceSupported = await auth.isDeviceSupported();

      if (canCheckBiometrics == false || isDeviceSupported == false) {
        if (mounted) {
          setState(() {
            errorMessage = 'Face ID is not available on this device.';
          });
        }
        return;
      }

      final authenticated = await auth.authenticate(
        localizedReason: 'Authenticate to access 999 Signal Intelligence Pro',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );

      if (authenticated == false) {
        if (mounted) {
          setState(() {
            errorMessage = 'Face ID verification was cancelled.';
          });
        }
        return;
      }

      final savedEmail = await secureStorage.read(key: savedEmailKey);
      final savedPassword = await secureStorage.read(key: savedPasswordKey);

      if (savedEmail == null ||
          savedEmail.isEmpty ||
          savedPassword == null ||
          savedPassword.isEmpty) {
        if (mounted) {
          setState(() {
            errorMessage =
                'Face ID verified. Log in with email and password once to enable Face ID login.';
          });
        }
        return;
      }

      await Supabase.instance.client.auth.signInWithPassword(
        email: savedEmail,
        password: savedPassword,
      );
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Face ID login failed: ${e.message}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Face ID failed: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              color: const Color(0xFF0D1428),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '999 SIGNAL INTELLIGENCE 2.0',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      onSubmitted: (_) => signIn(),
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ],
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loading ? null : signIn,
                        child: Text(loading ? 'Signing in...' : 'LOGIN'),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // FACE ID / PASSKEY LOGIN
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: loading ? null : signInWithFaceId,
                        icon: const Icon(
                          Icons.face,
                          size: 20,
                        ),
                        label: const Text(
                          'FACE ID',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF00E5FF),
                          side: const BorderSide(
                            color: Color(0xFF00E5FF),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
