import 'package:flutter/material.dart';
import 'package:kohlberg/services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String userId;

  const ResetPasswordScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool loading = false;
  String? errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Contraseña'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Crea una nueva contraseña',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Nueva contraseña',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirmar nueva contraseña',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword 
                        ? Icons.visibility_off 
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                  },
                ),
              ),
            ),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : _resetPassword,
                child: loading 
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Cambiar Contraseña'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resetPassword() async {
    if (passwordController.text.isEmpty || 
        confirmPasswordController.text.isEmpty) {
      setState(() => errorMessage = 'Por favor completa ambos campos');
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      setState(() => errorMessage = 'Las contraseñas no coinciden');
      return;
    }

    if (passwordController.text.length < 6) {
      setState(() => errorMessage = 'La contraseña debe tener al menos 6 caracteres');
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
    });

    final result = await AuthService.resetPassword(
      widget.userId,
      passwordController.text.trim(),
    );

    setState(() => loading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      setState(() => errorMessage = result['message']);
    }
  }
}