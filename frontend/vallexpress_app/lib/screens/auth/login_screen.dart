import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vallexpress_app/providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin(BuildContext context) {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.read<AuthProvider>().login(email, password).then((success) {
      if (success) {
        Navigator.of(context).pushReplacementNamed(AppConstants.homeRoute);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<AuthProvider>().error ?? 'Error al iniciar sesión',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // Logo
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.borderColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 120,
                  height: 120,
                ),
              ),

              const SizedBox(height: 40),

              // Bienvenido
              Text(
                'Bienvenido',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Inicia sesión para continuar',
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 32),

              // Email input
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: AppTheme.textPrimaryColor),
                decoration: InputDecoration(
                  hintText: 'tu@email.com',
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: AppTheme.borderColor,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Password input
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: AppTheme.textPrimaryColor),
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: AppTheme.borderColor,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppTheme.borderColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Forgot password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Login button
              Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: authProvider.isLoading
                          ? null
                          : () => _handleLogin(context),
                      child: authProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.backgroundColor,
                                ),
                              ),
                            )
                          : const Text('Iniciar Sesión'),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Divider
              /*Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      color: AppTheme.borderColor.withOpacity(0.3),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'o continúa con',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: AppTheme.borderColor.withOpacity(0.3),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Social buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Implementar login con Google
                      },
                      icon: const Icon(Icons.g_mobiledata),
                      label: const Text('Google'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimaryColor,
                        side: BorderSide(
                          color: AppTheme.borderColor.withOpacity(0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Facebook button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Implementar login con Facebook
                      },
                      icon: const Icon(Icons.facebook),
                      label: const Text('Facebook'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimaryColor,
                        side: BorderSide(
                          color: AppTheme.borderColor.withOpacity(0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),*/
              const SizedBox(height: 20),

              // Register link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '¿No tienes cuenta? ',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(
                        context,
                      ).pushNamed(AppConstants.registerRoute);
                    },
                    child: const Text(
                      'Regístrate aquí',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
