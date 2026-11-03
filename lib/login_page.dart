import 'package:flutter/material.dart';

import 'common.dart';
import 'home_page.dart';

/// The only account that can log in.
const kUsername = 'PanhaShen';
const kPassword = 'Panhakoko99';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _hidePassword = true;
  String? _error;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _login() {
    FocusScope.of(context).unfocus();
    if (_user.text.trim() == kUsername && _pass.text == kPassword) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage(username: kUsername)),
      );
    } else {
      setState(() => _error = 'Wrong username or password.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: GameBackground(
        dim: 0.45,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
                  decoration: BoxDecoration(
                    color: kPanel,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: kOrange.withOpacity(0.7), width: 1.5),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const GameTitle(size: 38),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _user,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _pass,
                        obscureText: _hidePassword,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _login(),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          isDense: true,
                          suffixIcon: IconButton(
                            icon: Icon(_hidePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _hidePassword = !_hidePassword),
                          ),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(_error!, style: const TextStyle(color: Color(0xFFFF6B6B))),
                      ],
                      const SizedBox(height: 16),
                      GameButton(label: 'LOGIN', onPressed: _login, width: double.infinity),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
