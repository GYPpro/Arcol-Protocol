import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../api/api_client.dart';

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
  UsernameCheckState _usernameCheckState = UsernameCheckState.idle;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onUsernameChanged() {
    if (!_isLogin && _usernameController.text.length >= 3) {
      _checkUsernameAvailability();
    } else {
      setState(() => _usernameCheckState = UsernameCheckState.idle);
    }
  }

  Future<void> _checkUsernameAvailability() async {
    final username = _usernameController.text.trim();
    if (username.length < 3) return;

    setState(() => _usernameCheckState = UsernameCheckState.checking);

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/auth/available', queryParameters: {'username': username});
      if (response.data['available'] == true) {
        setState(() => _usernameCheckState = UsernameCheckState.available);
      } else {
        setState(() => _usernameCheckState = UsernameCheckState.taken);
      }
    } catch (e) {
      setState(() => _usernameCheckState = UsernameCheckState.idle);
    }
  }

  void _submit() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty) {
      _showErrorDialog('Username is required');
      return;
    }

    if (password.isEmpty) {
      _showErrorDialog('Password is required');
      return;
    }

    if (!_isLogin && password.length < 6) {
      _showErrorDialog('Password must be at least 6 characters');
      return;
    }

    if (_isLogin) {
      ref.read(authProvider.notifier).login(username, password);
    } else {
      if (_usernameCheckState == UsernameCheckState.taken) {
        _showErrorDialog('Username is already taken');
        return;
      }
      ref.read(authProvider.notifier).register(username, password, null);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Color _getUsernameBorderColor() {
    if (!_isLogin) {
      switch (_usernameCheckState) {
        case UsernameCheckState.available:
          return Colors.green;
        case UsernameCheckState.taken:
          return Colors.red;
        case UsernameCheckState.checking:
          return Colors.orange;
        case UsernameCheckState.idle:
          break;
      }
    }
    return Theme.of(context).colorScheme.outline;
  }

  IconData? _getUsernameSuffixIcon() {
    if (!_isLogin) {
      switch (_usernameCheckState) {
        case UsernameCheckState.available:
          return Icons.check_circle;
        case UsernameCheckState.taken:
          return Icons.error;
        case UsernameCheckState.checking:
          return null;
        case UsernameCheckState.idle:
          return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated) {
        context.go('/dashboard');
      }
      if (next.error != null && next.error != (previous?.error)) {
        String message = next.error!;
        if (message.contains('400')) {
          if (message.contains('Username already')) {
            message = 'Username is already registered';
          } else if (message.contains('Email already')) {
            message = 'Email is already registered';
          } else {
            message = 'Registration failed. Please try again.';
          }
        } else if (message.contains('401')) {
          message = 'Invalid username or password';
        }
        _showErrorDialog(message);
      }
    });

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.dashboard_rounded, size: 80, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  'Arcol Protocol',
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person),
                    suffixIcon: _getUsernameSuffixIcon() != null
                        ? Icon(_getUsernameSuffixIcon(), color: _getUsernameBorderColor())
                        : null,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: _getUsernameBorderColor()),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: _getUsernameBorderColor(), width: 2),
                    ),
                  ),
                ),
                if (!_isLogin && _usernameCheckState == UsernameCheckState.checking)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 12),
                    child: Text(
                      'Checking availability...',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange),
                    ),
                  ),
                if (!_isLogin && _usernameCheckState == UsernameCheckState.available)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 12),
                    child: Text(
                      'Username is available',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.green),
                    ),
                  ),
                if (!_isLogin && _usernameCheckState == UsernameCheckState.taken)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 12),
                    child: Text(
                      'Username is already taken',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
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
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  obscureText: _obscurePassword,
                ),
                if (!_isLogin)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 12),
                    child: Text(
                      'Password must be at least 6 characters',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: authState.isLoading ? null : _submit,
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isLogin ? 'Login' : 'Register'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                      _usernameCheckState = UsernameCheckState.idle;
                    });
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
    );
  }
}

enum UsernameCheckState { idle, checking, available, taken }
