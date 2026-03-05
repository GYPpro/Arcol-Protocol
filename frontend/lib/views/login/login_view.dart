import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';

class DebugLog {
  static final List<String> _logs = [];
  static void add(String msg) {
    _logs.add('${DateTime.now().toIso8601String().substring(11,19)} $msg');
    if (_logs.length > 50) _logs.removeAt(0);
    debugPrint(msg);
  }
  static List<String> get logs => List.unmodifiable(_logs);
  static void clear() => _logs.clear();
}

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    DebugLog.add('[LOGIN] initState');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    DebugLog.add('[LOGIN] _submit isLogin=$_isLogin');
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    
    if (username.isEmpty || password.isEmpty) {
      DebugLog.add('[LOGIN] Empty fields');
      return;
    }

    if (_isLogin) {
      DebugLog.add('[LOGIN] Calling login');
      ref.read(authProvider.notifier).login(username, password);
    } else {
      DebugLog.add('[LOGIN] Calling register');
      ref.read(authProvider.notifier).register(username, password, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    DebugLog.add('[LOGIN] build()');
    final authState = ref.watch(authProvider);
    
    ref.listen<AuthState>(authProvider, (previous, next) {
      DebugLog.add('[LOGIN] Auth: isAuth=${next.isAuthenticated} err=${next.error}');
      if (next.isAuthenticated) {
        context.go('/dashboard');
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.dashboard_rounded, size: 80, color: Colors.blue),
                    const SizedBox(height: 16),
                    Text(
                      'Arcol Protocol',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () {
                            DebugLog.add('[LOGIN] toggle password');
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        DebugLog.add('[LOGIN] Button CLICKED!');
                        _submit();
                      },
                      child: Text(_isLogin ? 'Login' : 'Register'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        DebugLog.add('[LOGIN] toggle mode');
                        setState(() => _isLogin = !_isLogin);
                      },
                      child: Text(_isLogin ? 'Create account' : 'Have account?'),
                    ),
                    const SizedBox(height: 32),
                    OutlinedButton(
                      onPressed: () => context.go('/guest'),
                      child: const Text('Guest Panel'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Debug panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              color: Colors.black87,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        const Text('DEBUG', style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        TextButton(
                          onPressed: () => setState(() {}),
                          child: const Text('R', style: TextStyle(color: Colors.white)),
                        ),
                        TextButton(
                          onPressed: () => DebugLog.clear(),
                          child: const Text('C', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: DebugLog.logs.length,
                      itemBuilder: (context, index) {
                        return Text(
                          DebugLog.logs[index],
                          style: const TextStyle(color: Colors.green, fontSize: 9, fontFamily: 'monospace'),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
