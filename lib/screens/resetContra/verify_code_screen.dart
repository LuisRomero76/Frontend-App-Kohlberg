import 'package:flutter/material.dart';
import 'package:kohlberg/screens/resetContra/reset_password_screen.dart';
import 'package:kohlberg/services/auth_service.dart';

class VerifyCodeScreen extends StatefulWidget {
  final String email;

  const VerifyCodeScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final codeController = TextEditingController();
  bool loading = false;
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificar Código'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ingresa el código enviado a ${widget.email}',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                labelText: 'Código de verificación',
                border: OutlineInputBorder(),
                errorText: errorMessage,
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : _verifyCode,
                child: loading 
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Verificar Código'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyCode() async {
    if (codeController.text.isEmpty) {
      setState(() => errorMessage = 'Por favor ingresa el código');
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
    });

    final result = await AuthService.verifyResetCode(
      widget.email,
      codeController.text.trim(),
    );

    setState(() => loading = false);

    if (result['success'] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(
            userId: result['persona_id'].toString(),
          ),
        ),
      );
    } else {
      setState(() => errorMessage = result['message']);
    }
  }
}