import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../widgets/terms_and_conditions_modal.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String? _selectedRole;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

  // Controllers
  late TextEditingController _nombreController;
  late TextEditingController _apellidoController;
  late TextEditingController _emailController;
  late TextEditingController _telefonoController;
  late TextEditingController _cedulaController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  // Campos específicos por rol
  late TextEditingController _nombreNegocioController;
  late TextEditingController _vehiculoController;
  late TextEditingController _placaController;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController();
    _apellidoController = TextEditingController();
    _emailController = TextEditingController();
    _telefonoController = TextEditingController();
    _cedulaController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _nombreNegocioController = TextEditingController();
    _vehiculoController = TextEditingController();
    _placaController = TextEditingController();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _cedulaController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nombreNegocioController.dispose();
    _vehiculoController.dispose();
    _placaController.dispose();
    super.dispose();
  }

  void _handleRegister(BuildContext context) {
    // Validaciones básicas
    if (_selectedRole == null) {
      _showError('Por favor selecciona un rol');
      return;
    }

    if (_nombreController.text.isEmpty ||
        _apellidoController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _telefonoController.text.isEmpty ||
        _cedulaController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showError('Por favor completa todos los campos');
      return;
    }

    if (_cedulaController.text.length != 10) {
      _showError('La cédula debe tener 10 dígitos');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Las contraseñas no coinciden');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showError('La contraseña debe tener al menos 6 caracteres');
      return;
    }

    if (!_acceptTerms) {
      _showError('Debes aceptar los términos y condiciones');
      return;
    }

    // Campos específicos según rol
    if (_selectedRole == 'vendedor' && _nombreNegocioController.text.isEmpty) {
      _showError('Por favor ingresa el nombre del negocio');
      return;
    }

    if (_selectedRole == 'repartidor' &&
        (_vehiculoController.text.isEmpty || _placaController.text.isEmpty)) {
      _showError('Por favor completa los datos del vehículo');
      return;
    }

    // Llamar al provider para registrarse
    context
        .read<AuthProvider>()
        .register(
          nombre: _nombreController.text,
          apellido: _apellidoController.text,
          email: _emailController.text,
          telefono: _telefonoController.text,
          cedula: _cedulaController.text,
          password: _passwordController.text,
          tipoUsuario: _selectedRole!,
          nombreNegocio: _selectedRole == 'vendedor' ? _nombreNegocioController.text : null,
          vehiculo: _selectedRole == 'repartidor' ? _vehiculoController.text : null,
          placa: _selectedRole == 'repartidor' ? _placaController.text : null,
        )
        .then((success) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('¡Registrado exitosamente!'),
                backgroundColor: Colors.green,
              ),
            );
            // Ir al login
            Navigator.of(context).pushReplacementNamed(AppConstants.loginRoute);
          } else {
            _showError(
              context.read<AuthProvider>().error ?? 'Error al registrar',
            );
          }
        });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Logo
              Center(
                child: Container(
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
                    width: 100,
                    height: 100,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Título
              Center(
                child: Text(
                  'Crear Cuenta',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Center(
                child: Text(
                  'Únete a ValleXpress',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),

              const SizedBox(height: 24),

              // Selector de Rol
              Text(
                'Selecciona tu rol',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 12),

              // Radio buttons para roles
              Column(
                children: [
                  _buildRoleOption('cliente', '👤 Cliente'),
                  const SizedBox(height: 12),
                  _buildRoleOption('vendedor', '🏪 Vendedor'),
                  const SizedBox(height: 12),
                  _buildRoleOption('repartidor', '🚚 Repartidor'),
                ],
              ),

              const SizedBox(height: 24),

              // Formulario de registro
              if (_selectedRole != null) ...[
                // Nombre
                TextField(
                  controller: _nombreController,
                  style: const TextStyle(color: AppTheme.textPrimaryColor),
                  decoration: InputDecoration(
                    hintText: 'Nombre',
                    prefixIcon: const Icon(
                      Icons.person_outline,
                      color: AppTheme.borderColor,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Apellido
                TextField(
                  controller: _apellidoController,
                  style: const TextStyle(color: AppTheme.textPrimaryColor),
                  decoration: InputDecoration(
                    hintText: 'Apellido',
                    prefixIcon: const Icon(
                      Icons.person_outline,
                      color: AppTheme.borderColor,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Cédula
                TextField(
                  controller: _cedulaController,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  style: const TextStyle(color: AppTheme.textPrimaryColor),
                  decoration: InputDecoration(
                    hintText: 'Ejm: 0123456789 - 10 dígitos',
                    prefixIcon: const Icon(
                      Icons.credit_card_outlined,
                      color: AppTheme.borderColor,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Email
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

                const SizedBox(height: 16),

                // Teléfono
                TextField(
                  controller: _telefonoController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: AppTheme.textPrimaryColor),
                  decoration: InputDecoration(
                    hintText: '+593 9 87654321',
                    prefixIcon: const Icon(
                      Icons.phone_outlined,
                      color: AppTheme.borderColor,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Campos específicos por rol
                if (_selectedRole == 'vendedor')
                  Column(
                    children: [
                      TextField(
                        controller: _nombreNegocioController,
                        style: const TextStyle(
                          color: AppTheme.textPrimaryColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Nombre del negocio',
                          prefixIcon: const Icon(
                            Icons.store_outlined,
                            color: AppTheme.borderColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                if (_selectedRole == 'repartidor')
                  Column(
                    children: [
                      TextField(
                        controller: _vehiculoController,
                        style: const TextStyle(
                          color: AppTheme.textPrimaryColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Tipo de vehículo',
                          prefixIcon: const Icon(
                            Icons.two_wheeler_outlined,
                            color: AppTheme.borderColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _placaController,
                        style: const TextStyle(
                          color: AppTheme.textPrimaryColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Placa del vehículo',
                          prefixIcon: const Icon(
                            Icons.confirmation_number_outlined,
                            color: AppTheme.borderColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // Contraseña
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

                const SizedBox(height: 16),

                // Confirmar Contraseña
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: const TextStyle(color: AppTheme.textPrimaryColor),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: AppTheme.borderColor,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppTheme.borderColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                // Términos y condiciones
                Row(
                  children: [
                    Checkbox(
                      value: _acceptTerms,
                      onChanged: (value) {
                        setState(() {
                          _acceptTerms = value ?? false;
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => TermsAndConditionsModal(
                                    userRole: _selectedRole ?? 'cliente',
                                  ),
                                );
                              },
                              child: Text(
                                'Acepto los términos y condiciones',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppTheme.primaryColor,
                                      decoration: TextDecoration.underline,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Botón Registrarse
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: authProvider.isLoading
                            ? null
                            : () => _handleRegister(context),
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
                            : const Text('Crear Cuenta'),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Ya tienes cuenta
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿Ya tienes cuenta? ',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(
                            context,
                          ).pushReplacementNamed(AppConstants.loginRoute);
                        },
                        child: const Text(
                          'Inicia sesión',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleOption(String value, String label) {
    return Container(
      decoration: BoxDecoration(
        color: _selectedRole == value
            ? AppTheme.cardColor
            : AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _selectedRole == value
              ? AppTheme.primaryColor
              : AppTheme.borderColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: _selectedRole,
        onChanged: (newValue) {
          setState(() {
            _selectedRole = newValue;
          });
        },
        activeColor: AppTheme.primaryColor,
        title: Text(
          label,
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
