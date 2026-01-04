import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:mobile_app/services/auth_api.dart';
import 'package:mobile_app/session/session.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  bool loading = true;
  bool saving = false;
  String? errorText;

  Map<String, dynamic>? me;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();

  int? _grade; // 3,4,5
  String? _disabilityType;

  final List<String> _disabilityOptions = const [
    "visual",
    "hearing",
    "physical",
    "cognitive",
  ];

  @override
  void initState() {
    super.initState();
    _loadMe();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMe() async {
    try {
      final token = Session.token;
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() {
          loading = false;
          errorText = "Not logged in";
        });
        return;
      }

      final url = Uri.parse("${AuthApi.baseUrl}/api/me");
      final res = await http.get(url, headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      });

      if (res.statusCode != 200) {
        if (!mounted) return;
        setState(() {
          loading = false;
          errorText = "Failed: ${res.statusCode}\n${res.body}";
        });
        return;
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception("Invalid response format");
      }

      final data = (decoded["data"] is Map<String, dynamic>)
          ? decoded["data"] as Map<String, dynamic>
          : decoded;

      me = data;

      // Fill form fields
      _nameCtrl.text = (data["name"] ?? "").toString();
      _emailCtrl.text = (data["email"] ?? "").toString();

      _disabilityType = (data["disabilityType"] ?? "").toString();
      if (_disabilityType != null && _disabilityType!.isEmpty) {
        _disabilityType = null;
      }

      final student = (data["student"] is Map<String, dynamic>)
          ? data["student"] as Map<String, dynamic>
          : null;

      final g = student?["grade"];
      if (g != null) _grade = int.tryParse(g.toString());

      final a = student?["age"];
      if (a != null) _ageCtrl.text = a.toString();

      if (!mounted) return;
      setState(() {
        loading = false;
        errorText = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        errorText = e.toString();
      });
    }
  }

  Future<void> _save() async {
    try {
      final token = Session.token;
      if (token == null || token.isEmpty) return;

      final name = _nameCtrl.text.trim();
      if (name.isEmpty) {
        setState(() => errorText = "Name is required");
        return;
      }

      setState(() {
        saving = true;
        errorText = null;
      });

      final body = <String, dynamic>{
        "name": name,
        "disabilityType": _disabilityType,
        "student": {
          "grade": _grade,
          "age": _ageCtrl.text.trim().isEmpty ? null : int.tryParse(_ageCtrl.text.trim()),
        }
      };

      final url = Uri.parse("${AuthApi.baseUrl}/api/me");
      final res = await http.put(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      if (res.statusCode != 200) {
        setState(() {
          saving = false;
          errorText = "Update failed: ${res.statusCode}\n${res.body}";
        });
        return;
      }

      // Success
      if (!mounted) return;
      setState(() {
        saving = false;
      });

      Navigator.pop(context, true); // return true -> changed
    } catch (e) {
      setState(() {
        saving = false;
        errorText = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorText != null && me == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Edit Profile")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(errorText!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      loading = true;
                      errorText = null;
                    });
                    _loadMe();
                  },
                  child: const Text("Retry"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (errorText != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.35)),
                  ),
                  child: Text(errorText!, style: const TextStyle(color: Colors.red)),
                ),

              _fieldLabel("Name"),
              TextField(
                controller: _nameCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Enter name",
                ),
              ),
              const SizedBox(height: 14),

              _fieldLabel("Email (read-only)"),
              TextField(
                controller: _emailCtrl,
                enabled: false,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),

              _fieldLabel("Disability Type"),
              DropdownButtonFormField<String>(
                value: _disabilityType,
                items: _disabilityOptions
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setState(() => _disabilityType = v),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Select type",
                ),
              ),
              const SizedBox(height: 14),

              _fieldLabel("Grade"),
              DropdownButtonFormField<int>(
                value: _grade,
                items: const [
                  DropdownMenuItem(value: 3, child: Text("3")),
                  DropdownMenuItem(value: 4, child: Text("4")),
                  DropdownMenuItem(value: 5, child: Text("5")),
                ],
                onChanged: (v) => setState(() => _grade = v),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Select grade",
                ),
              ),
              const SizedBox(height: 14),

              _fieldLabel("Age"),
              TextField(
                controller: _ageCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Enter age (optional)",
                ),
              ),
              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: saving ? null : _save,
                  icon: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(saving ? "Saving..." : "Save"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
