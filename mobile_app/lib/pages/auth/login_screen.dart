import 'package:flutter/material.dart';
import 'package:mobile_app/services/auth_api.dart';
import 'package:mobile_app/session/session.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    setState(() => _isLoading = true);

    try {
      // 1️⃣ Call backend login – EXPECTS { token, user }
      final result = await AuthApi.login(email: email, password: password);

      final token = result['token'];
      final user = result['user'] as Map<String, dynamic>?;

      // 2️⃣ Save ALL important data to Session
      Session.token = token?.toString();
      Session.userId = user?['id']?.toString();
      Session.userName = user?['name']?.toString();
      Session.email = user?['email']?.toString();
      Session.disabilityType = user?['disabilityType']?.toString();

      print('JWT token set: ${Session.token}');
      print('Session.userName = ${Session.userName}');
      print('Session.disabilityType = ${Session.disabilityType}');

      // 3️⃣ Decide which route to open based on disabilityType
      final String? disabilityType = Session.disabilityType;
      String targetRoute = '/dashboard'; // fallback

      if (disabilityType == 'visual') {
        targetRoute = '/home_visual';
      } else if (disabilityType == 'hearing') {
        targetRoute = '/home_hearing';
      } else if (disabilityType == 'physical') {
        targetRoute = '/home_physical';
      } else if (disabilityType == 'cognitive') {
        targetRoute = '/iq_game';
      }

      if (!mounted) return;

      // 4️⃣ Navigate to dashboard for that disability type
      Navigator.pushReplacementNamed(context, targetRoute);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Login successful"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Login failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;

          Widget formCard = Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 48,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Welcome Back!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Start your learning journey 🌟",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Email Field
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7F7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF2D3748),
                          ),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(
                              Icons.email_rounded,
                              color: Colors.blueGrey,
                            ),
                            border: InputBorder.none,
                            hintText: "ඇතුලත් කරන්න : Email",
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 15,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please enter your email";
                            }
                            if (!value.contains("@")) {
                              return "Enter a valid email";
                            }
                            return null;
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Password Field
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7F7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF2D3748),
                          ),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.lock_rounded,
                              color: Colors.blueGrey,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: Colors.grey[600],
                              ),
                            ),
                            border: InputBorder.none,
                            hintText: "ඇතුලත් කරන්න : Password",
                            hintStyle: const TextStyle(
                              color: Colors.grey,
                              fontSize: 15,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please enter your password";
                            }
                            if (value.length < 6) {
                              return "Password must be at least 6 characters";
                            }
                            return null;
                          },
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "Login",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Sign Up Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: () {
                              // Navigate to sign up page
                            },
                            child: const Text(
                              "Sign up",
                              style: TextStyle(
                                color: Color(0xFF4F46E5),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        "For Grade 3, 4, and 5 students",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );

          if (isWide) {
            return Row(
              children: [
                // LEFT SIDE — IMAGE (Keep original image)
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF8EC5FC), Color(0xFFE0C3FC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Image.asset(
                        "assets/login_page.png",
                        width: constraints.maxWidth * 0.4,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                // RIGHT SIDE — FORM
                Expanded(
                  flex: 1,
                  child: Container(color: Colors.grey[50], child: formCard),
                ),
              ],
            );
          } else {
            return Column(
              children: [
                // TOP — IMAGE
                Expanded(
                  flex: 4,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF8EC5FC), Color(0xFFE0C3FC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Image.asset(
                        "assets/login_page.png",
                        width: constraints.maxWidth * 0.8,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                // BOTTOM — FORM
                Expanded(
                  flex: 5,
                  child: Container(color: Colors.grey[50], child: formCard),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
