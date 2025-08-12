import 'package:flutter/material.dart';
import 'package:kohlberg/screens/main_navigation_screen.dart';
import 'package:kohlberg/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final nombreController = TextEditingController();
  final apellidoController = TextEditingController();
  final usernameController = TextEditingController();
  final telefonoController = TextEditingController();
  final direccionController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  
  bool loading = false;
  String? errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (passwordController.text != confirmPasswordController.text) {
      setState(() => errorMessage = 'Las contraseñas no coinciden');
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
    });

    final success = await AuthService.register(
      nombre: nombreController.text.trim(),
      apellido: apellidoController.text.trim(),
      username: usernameController.text.trim(),
      telefono: telefonoController.text.trim(),
      direccion: direccionController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    setState(() => loading = false);

    if (success && mounted) {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (_) => const MainNavigationScreen())
      );
    } else if (mounted) {
      setState(() {
        errorMessage = AuthService.lastErrorMessage ?? 'Registro fallido';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage!),
          backgroundColor: Colors.red,
        )
      );
    }
  }

  @override
  void dispose() {
    nombreController.dispose();
    apellidoController.dispose();
    usernameController.dispose();
    telefonoController.dispose();
    direccionController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo circular (igual que en login)
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/logo.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Título (estilo igual que login)
                  const Text(
                    'Vinos Kohlberg',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Subtítulo (estilo igual que login)
                  const Text(
                    'Crear Cuenta',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ingresa los datos para registrarte',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Campo Nombre
                  _buildTextField(
                    controller: nombreController,
                    label: 'Nombre',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese su nombre';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campo Apellido
                  _buildTextField(
                    controller: apellidoController,
                    label: 'Apellido',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese su apellido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campo Nombre de Usuario
                  _buildTextField(
                    controller: usernameController,
                    label: 'Nombre de usuario',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese un nombre de usuario';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campo Teléfono
                  _buildTextField(
                    controller: telefonoController,
                    label: 'Teléfono',
                    keyboardType: TextInputType.phone,
                    hintText: 'Ej: 61234567',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese su teléfono';
                      }
                      if (!RegExp(r'^[67]\d{7}$').hasMatch(value)) {
                        return 'Debe comenzar con 6 o 7 y tener 8 dígitos';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campo Dirección
                  _buildTextField(
                    controller: direccionController,
                    label: 'Dirección',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese su dirección';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campo Email
                  _buildTextField(
                    controller: emailController,
                    label: 'Correo electrónico',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese su email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Ingrese un email válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campo Contraseña
                  _buildTextField(
                    controller: passwordController,
                    label: 'Contraseña',
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese una contraseña';
                      }
                      if (value.length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campo Confirmar Contraseña
                  _buildTextField(
                    controller: confirmPasswordController,
                    label: 'Confirmar contraseña',
                    obscureText: _obscureConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor confirme su contraseña';
                      }
                      if (value != passwordController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        '¿Ya tienes cuenta? Inicia sesión',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  
                  // Botón de Continuar (estilo igual que login)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'CONTINUAR',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14
        ),
        suffixIcon: suffixIcon,
      ),
      validator: validator,
    );
  }
}