import 'package:flutter/material.dart';
import 'package:kohlberg/screens/resetContra/verify_code_screen.dart';
import 'package:kohlberg/services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  bool loading = false;
  String? errorMessage;
  String? successMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar Contraseña'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingresa tu correo electrónico',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                errorText: errorMessage,
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            if (successMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  successMessage!,
                  style: TextStyle(color: Colors.green),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : _sendResetCode,
                child: loading 
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Enviar Código'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendResetCode() async {
    if (emailController.text.isEmpty) {
      setState(() => errorMessage = 'Por favor ingresa tu email');
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
      successMessage = null;
    });

    final result = await AuthService.requestPasswordReset(emailController.text.trim());

    setState(() => loading = false);

    if (result['success'] == true) {
      setState(() => successMessage = result['message']);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyCodeScreen(email: emailController.text.trim()),
        ),
      );
    } else {
      setState(() => errorMessage = result['message']);
    }
  }
}