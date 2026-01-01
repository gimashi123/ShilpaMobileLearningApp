import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mobile_app/services/auth_api.dart';

class RegisterPage extends StatefulWidget {
  final String disabilityType; // visual / hearing / physical / cognitive

  const RegisterPage({super.key, required this.disabilityType});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _gradeCtrl = TextEditingController(); // 👈 NEW

  // Role (default = student)
  String _selectedRole = 'student';

  // TTS
  final FlutterTts _tts = FlutterTts();
  static const String _welcomeText =
      'ශිෂ්‍ය ගිණුමක් නිර්මාණය කරන්න. '
      'ඔබගේ නම, ඊමේල් ලිපිනය, සංකේත පදය, ශ්‍රේණිය සහ භූමිකාව තෝරන්න.';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speak(_welcomeText);
    });
  }

  @override
  void dispose() {
    _tts.stop();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _gradeCtrl.dispose();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);

    var ok = await _tts.setLanguage('si-LK');
    if (ok == 0) {
      await _tts.setLanguage('en-US');
    }

    await _tts.stop();
    await _tts.speak(text);
  }

  // --------- helpers ---------

  String _roleLabel(String role) {
    switch (role) {
      case 'teacher':
        return 'ගුරු';
      case 'parent':
        return 'මාතා පියා';
      case 'admin':
        return 'පරිපාලක';
      case 'student':
      default:
        return 'ශිෂ්‍ය';
    }
  }

  String _disabilityLabel(String type) {
    switch (type) {
      case 'visual':
        return 'දෘශ්‍ය අබාධිත ශිෂ්‍ය';
      case 'hearing':
        return 'ශ්‍රවණ අබාධිත ශිෂ්‍ය';
      case 'physical':
        return 'ශාරීරික අබාධිත ශිෂ්‍ය';
      case 'cognitive':
        return 'ඥානීය / බුද්ධිමය ශිෂ්‍ය';
      default:
        return 'ශිෂ්‍ය';
    }
  }

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF7C4DFF)),
      labelStyle: const TextStyle(
        color: Color(0xFF5E35B1),
        fontWeight: FontWeight.w500,
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFB39DDB)),
        borderRadius: BorderRadius.circular(18),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF7C4DFF), width: 2),
        borderRadius: BorderRadius.circular(18),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  // --------- submit ---------

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameCtrl.text.trim();
      final email = _emailCtrl.text.trim();
      final password = _passwordCtrl.text.trim();
      final role = _selectedRole;
      final gradeText = _gradeCtrl.text.trim();

      // extra safety: backend also checks, but we guard here
      String? gradeToSend;
      if (role == 'student') {
        if (gradeText.isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("ශ්‍රේණිය අවශ්‍යයි")));
          await _speak('කරුණාකර ඔබගේ ශ්‍රේණිය ඇතුල් කරන්න.');
          return;
        }
        final g = int.tryParse(gradeText);
        if (g == null || g < 3 || g > 5) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("ශ්‍රේණිය 3, 4, හෝ 5 විය යුතුය")),
          );
          await _speak('ශ්‍රේණිය 3, 4, හෝ 5 විය යුතුය.');
          return;
        }
        gradeToSend = gradeText; // backend will convert to number
      }

      try {
        await AuthApi.register(
          name: name,
          email: email,
          password: password,
          role: role,
          disabilityType: widget.disabilityType,
          grade: gradeToSend, // 👈 NEW
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Successfully Registered")),
        );

        await _speak('ඔබ ${_roleLabel(role)} ලෙස සාර්ථකව ලියාපදිංචි විය.');

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/newlogin');
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Register failed: $e")));
        await _speak('ලියාපදිංචිය අසාර්ථක විය. නැවත උත්සහ කරන්න.');
      }
    } else {
      await _speak('කරුණාකර සියලු අවශ්‍ය තොරතුරු නිවැරදිව පුරවන්න.');
    }
  }

  Future<void> _goNewLogin(String spokenText) async {
    await _speak(spokenText);
    if (!mounted) return;
    Navigator.pushNamed(context, '/newlogin');
  }

  // --------- UI ---------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE3F2FD),
                  Color(0xFFF3E5F5),
                  Color(0xFFFFF8E1),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -40,
                  left: -30,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.lightBlueAccent.withOpacity(0.20),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -40,
                  right: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.pinkAccent.withOpacity(0.15),
                    ),
                  ),
                ),
                isWide
                    ? Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Image.asset(
                                        'assets/login_image.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(flex: 4, child: _buildFormCard()),
                        ],
                      )
                    : Column(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 24,
                                  right: 24,
                                  top: 48,
                                  bottom: 8,
                                ),
                                child: Image.asset(
                                  'assets/login_image.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          Expanded(flex: 5, child: _buildFormCard()),
                        ],
                      ),
                Positioned(
                  right: 16,
                  top: 32,
                  child: Material(
                    elevation: 3,
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                    child: IconButton(
                      icon: const Icon(
                        Icons.volume_up_rounded,
                        color: Color(0xFF7C4DFF),
                      ),
                      tooltip: 'Replay instructions',
                      onPressed: () => _speak(_welcomeText),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormCard() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    "ශිෂ්‍ය ගිණුමක්\nනිර්මාණය කරමු",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF4A148C),
                      fontSize: 24,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "ඔබගේ තොරතුරු නිවැරදිව ඇතුල් කරලා\nඉගෙනීමේ ගමනට සූදානම් වන්න.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  const SizedBox(height: 12),

                  // Disability type (read-only)
                  TextFormField(
                    enabled: false,
                    initialValue: _disabilityLabel(widget.disabilityType),
                    style: const TextStyle(
                      color: Color(0xFF4A148C),
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      labelText: "අබාධ වර්ගය",
                      prefixIcon: const Icon(
                        Icons.accessibility_new_rounded,
                        color: Color(0xFF7C4DFF),
                      ),
                      labelStyle: const TextStyle(
                        color: Color(0xFF5E35B1),
                        fontWeight: FontWeight.w500,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFFB39DDB)),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFFB39DDB)),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Name
                  TextFormField(
                    controller: _nameCtrl,
                    style: const TextStyle(color: Colors.black87),
                    decoration: _inputStyle("ඇතුල් කරන්න: නම", Icons.person),
                    validator: (v) =>
                        v == null || v.isEmpty ? "නම අවශ්‍යයි" : null,
                  ),
                  const SizedBox(height: 14),

                  // Email
                  TextFormField(
                    controller: _emailCtrl,
                    style: const TextStyle(color: Colors.black87),
                    decoration: _inputStyle(
                      "ඇතුල් කරන්න: Email",
                      Icons.email_rounded,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return "Email අවශ්‍යයි";
                      }
                      if (!v.contains("@")) {
                        return "වලංගු Email එකක් ලබා දෙන්න";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Password
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    style: const TextStyle(color: Colors.black87),
                    decoration: _inputStyle(
                      "ඇතුල් කරන්න: Password",
                      Icons.lock_rounded,
                    ),
                    validator: (v) => (v == null || v.length < 6)
                        ? "Password අකුරු 6ක් වත් අවශ්‍යයි"
                        : null,
                  ),
                  const SizedBox(height: 14),

                  // Grade (only validated for student)
                  TextFormField(
                    controller: _gradeCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.black87),
                    decoration: _inputStyle(
                      "ඇතුල් කරන්න: ශ්‍රේණිය (3 / 4 / 5)",
                      Icons.class_,
                    ),
                    validator: (v) {
                      if (_selectedRole != 'student') return null;
                      if (v == null || v.isEmpty) {
                        return "ශ්‍රේණිය අවශ්‍යයි";
                      }
                      final g = int.tryParse(v);
                      if (g == null || g < 3 || g > 5) {
                        return "ශ්‍රේණිය 3, 4, හෝ 5 විය යුතුය";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  // Role dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    dropdownColor: Colors.white,
                    decoration: _inputStyle("භූමිකාව තෝරන්න", Icons.school),
                    iconEnabledColor: const Color(0xFF7C4DFF),
                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                    items: const [
                      DropdownMenuItem(
                        value: 'student',
                        child: Text('ශිෂ්‍ය (Student)'),
                      ),
                      DropdownMenuItem(
                        value: 'teacher',
                        child: Text('ගුරු (Teacher)'),
                      ),
                      DropdownMenuItem(
                        value: 'parent',
                        child: Text('මාතා පියා (Parent)'),
                      ),
                      DropdownMenuItem(
                        value: 'admin',
                        child: Text('පරිපාලක (Admin)'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedRole = value);
                    },
                  ),

                  const SizedBox(height: 22),

                  // Register button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC857),
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: _submit,
                      child: const Text("Register ➜"),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Back to login
                  TextButton(
                    onPressed: () {
                      _goNewLogin(
                        'ඇතුල් වීමේ පිටුවට ගොස් ඔබගේ ගිණුමේ තොරතුරු ඇතුල් කරන්න.',
                      );
                    },
                    child: const Text(
                      "ඇතුල් වීමේ පිටුවට යන්න",
                      style: TextStyle(
                        color: Color(0xFF5E35B1),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
