import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPhoneController = TextEditingController();
  final _registerPasswordController = TextEditingController();

  bool _loggingIn = false;
  bool _registering = false;
  bool _socialLoading = false;

  bool get _busy => _loggingIn || _registering || _socialLoading;

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPhoneController.dispose();
    _registerPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _loggingIn = true);
    final provider = context.read<UserProvider>();
    final error = await provider.login(
      _loginEmailController.text.trim(),
      _loginPasswordController.text.trim(),
    );
    setState(() => _loggingIn = false);
    if (!mounted) return;
    if (error != null) {
      _showMessage(error);
      return;
    }
    Navigator.pushReplacementNamed(context, '/landing');
  }

  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;
    setState(() => _registering = true);
    final provider = context.read<UserProvider>();
    final error = await provider.register(
      name: _registerNameController.text.trim(),
      email: _registerEmailController.text.trim(),
      password: _registerPasswordController.text.trim(),
      phone: _registerPhoneController.text.trim().isEmpty
          ? null
          : _registerPhoneController.text.trim(),
    );
    setState(() => _registering = false);
    if (!mounted) return;
    if (error != null) {
      _showMessage(error);
      return;
    }
    _showMessage('Account created! You are now signed in.');
    Navigator.pushReplacementNamed(context, '/landing');
  }

  Future<void> _continueAsGuest() async {
    final provider = context.read<UserProvider>();
    await provider.continueAsGuest();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/landing');
  }

  Future<void> _handleGoogle() async {
    setState(() {
      _socialLoading = true;
    });
    final provider = context.read<UserProvider>();
    final error = await provider.signInWithGoogle();
    setState(() {
      _socialLoading = false;
    });
    if (!mounted) return;
    if (error != null) {
      _showMessage(error);
      return;
    }
    Navigator.pushReplacementNamed(context, '/landing');
  }

  Future<void> _handleApple() async {
    setState(() {
      _socialLoading = true;
    });
    final provider = context.read<UserProvider>();
    final error = await provider.signInWithApple();
    setState(() {
      _socialLoading = false;
    });
    if (!mounted) return;
    if (error != null) {
      _showMessage(error);
      return;
    }
    Navigator.pushReplacementNamed(context, '/landing');
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Account Access'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Sign In'),
              Tab(text: 'Create Account'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _AuthForm(
              formKey: _loginFormKey,
              isSubmitting: _loggingIn,
              submitLabel: 'Sign In',
              onSubmit: _handleLogin,
              children: [
                TextFormField(
                  controller: _loginEmailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value != null && value.contains('@')
                      ? null
                      : 'Enter a valid email',
                ),
                TextFormField(
                  controller: _loginPasswordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) => value != null && value.length >= 6
                      ? null
                      : 'Password must be 6+ characters',
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _loggingIn || _socialLoading ? null : _handleGoogle,
                  icon: const Icon(Icons.login),
                  label: const Text('Continue with Google'),
                ),
                const SizedBox(height: 8),
                if (!kIsWeb &&
                    (defaultTargetPlatform == TargetPlatform.iOS ||
                        defaultTargetPlatform == TargetPlatform.macOS))
                  OutlinedButton.icon(
                    onPressed:
                        _loggingIn || _socialLoading ? null : _handleApple,
                    icon: const Icon(Icons.apple),
                    label: const Text('Continue with Apple'),
                  ),
              ],
            ),
            _AuthForm(
              formKey: _registerFormKey,
              isSubmitting: _registering,
              submitLabel: 'Create Account',
              onSubmit: _handleRegister,
              children: [
                TextFormField(
                  controller: _registerNameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (value) => value != null && value.isNotEmpty
                      ? null
                      : 'Introduce yourself with a name',
                ),
                TextFormField(
                  controller: _registerEmailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value != null && value.contains('@')
                      ? null
                      : 'Enter a valid email',
                ),
                TextFormField(
                  controller: _registerPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone (optional)',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                TextFormField(
                  controller: _registerPasswordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) => value != null && value.length >= 6
                      ? null
                      : 'Password must be 6+ characters',
                ),
              ],
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () {
                      _continueAsGuest();
                    },
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Continue as guest'),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthForm extends StatelessWidget {
  const _AuthForm({
    required this.formKey,
    required this.children,
    required this.submitLabel,
    required this.onSubmit,
    required this.isSubmitting,
  });

  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final String submitLabel;
  final VoidCallback onSubmit;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...children,
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isSubmitting ? null : onSubmit,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(submitLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
