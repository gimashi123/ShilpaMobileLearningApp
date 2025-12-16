import 'package:flutter/material.dart';
import 'package:mobile_app/services/auth_api.dart'; // adjust path if needed

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

      // 2️⃣ Extract user + disabilityType safely
      final user = result['user'] as Map<String, dynamic>?;
      AuthApi.currentUser = user;
      final String? disabilityType = user != null
          ? user['disabilityType'] as String?
          : null;

      // 3️⃣ Decide which route to open
      String targetRoute = '/dashboard'; // fallback

      if (disabilityType == 'visual') {
        targetRoute = '/home_visual';
      } else if (disabilityType == 'hearing') {
        targetRoute = '/home_hearing';
      } else if (disabilityType == 'physical') {
        targetRoute = '/home_physical';
      } else if (disabilityType == 'cognitive') {
        targetRoute = '/home_cognitive';
      }

      if (!mounted) return;

      // 4️⃣ Navigate to dashboard for that disability type
      Navigator.pushReplacementNamed(context, targetRoute);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Login successful")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Login failed: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600; // Tablet / Large screen

          Widget formCard = Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Welcome!",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Start your learning journey 🌟",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),

                      // Email
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7F7),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.email_rounded),
                            border: InputBorder.none,
                            hintText: "Email",
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
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

                      const SizedBox(height: 16),

                      // Password
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7F7),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: TextFormField(
                          controller: _passwordCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.lock),
                            border: InputBorder.none,
                            hintText: "Password",
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
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

                      const SizedBox(height: 24),

                      // Login button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Login",
                                  style: TextStyle(fontSize: 18),
                                ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        "For Grade 3, 4, and 5 students",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );

          // 📱 Responsive layout: side-by-side on wide, stacked on small
          if (isWide) {
            return Row(
              children: [
                // LEFT SIDE — CHILDREN IMAGE
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
                        width: constraints.maxWidth * 0.3,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                // RIGHT SIDE — LOGIN FORM
                Expanded(flex: 1, child: formCard),
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
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                // BOTTOM — FORM
                Expanded(flex: 5, child: formCard),
              ],
            );
          }
        },
      ),
    );
  }
}
