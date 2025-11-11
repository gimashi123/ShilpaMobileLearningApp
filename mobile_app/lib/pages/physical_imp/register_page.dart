import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _showPassword = false;
  bool _agree = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok || !_agree) {
      if (!_agree) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please accept the terms.')),
        );
      }
      return;
    }
    // TODO: call your API here
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Registered successfully')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar with a built-in back button
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Register'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Horizontal layout optimized for landscape
            return Row(
              children: [
                // Left panel: branding / illustration (optional)
                if (constraints.maxWidth > 700)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.primaryContainer,
                            Theme.of(context).colorScheme.surfaceVariant,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.app_registration,
                              size: 96,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Create your account',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Quick sign-up to continue.',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Right panel: form
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Form(
                              key: _formKey,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person_add_alt_1,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Register',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Name + Phone in two columns for landscape
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _name,
                                          textInputAction: TextInputAction.next,
                                          decoration: const InputDecoration(
                                            labelText: 'Full Name',
                                            prefixIcon: Icon(Icons.person),
                                          ),
                                          validator: (v) =>
                                              (v == null || v.trim().length < 3)
                                              ? 'Enter a valid name'
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _phone,
                                          keyboardType: TextInputType.phone,
                                          textInputAction: TextInputAction.next,
                                          decoration: const InputDecoration(
                                            labelText: 'Phone',
                                            prefixIcon: Icon(Icons.phone),
                                          ),
                                          validator: (v) =>
                                              (v == null || v.trim().length < 7)
                                              ? 'Enter a valid phone'
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  TextFormField(
                                    controller: _email,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    decoration: const InputDecoration(
                                      labelText: 'Email',
                                      prefixIcon: Icon(Icons.email),
                                    ),
                                    validator: (v) {
                                      final email = v?.trim() ?? '';
                                      final ok = RegExp(
                                        r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                      ).hasMatch(email);
                                      return ok ? null : 'Enter a valid email';
                                    },
                                  ),
                                  const SizedBox(height: 12),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _password,
                                          obscureText: !_showPassword,
                                          textInputAction: TextInputAction.next,
                                          decoration: InputDecoration(
                                            labelText: 'Password',
                                            prefixIcon: const Icon(
                                              Icons.lock_outline,
                                            ),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _showPassword
                                                    ? Icons.visibility_off
                                                    : Icons.visibility,
                                              ),
                                              onPressed: () => setState(() {
                                                _showPassword = !_showPassword;
                                              }),
                                            ),
                                          ),
                                          validator: (v) =>
                                              (v == null || v.length < 6)
                                              ? 'Min 6 characters'
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _confirm,
                                          obscureText: !_showPassword,
                                          textInputAction: TextInputAction.done,
                                          decoration: const InputDecoration(
                                            labelText: 'Confirm Password',
                                            prefixIcon: Icon(
                                              Icons.lock_reset_outlined,
                                            ),
                                          ),
                                          validator: (v) => v == _password.text
                                              ? null
                                              : 'Passwords don’t match',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    value: _agree,
                                    onChanged: (v) =>
                                        setState(() => _agree = v ?? false),
                                    title: const Text(
                                      'I agree to the Terms & Privacy Policy',
                                    ),
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                  ),
                                  const SizedBox(height: 8),

                                  // Actions
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          icon: const Icon(Icons.arrow_back),
                                          label: const Text('Back'),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: FilledButton.icon(
                                          onPressed: _submit,
                                          icon: const Icon(Icons.check),
                                          label: const Text('Create Account'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// replace with this previouse register and login page if needed.
