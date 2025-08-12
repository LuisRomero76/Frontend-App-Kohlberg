import 'package:flutter/material.dart';
import 'package:kohlberg/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({Key? key}) : super(key: key);

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userId = await AuthService.getUserId();
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/usuarios/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        setState(() {
          _userData = userData;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Error al obtener los datos del usuario: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateField(String field, String value) async {
    final result = await AuthService.updateUserFieldWithMessage(field, value);
    if (result['success']) {
      setState(() {
        _userData![field] = value;
      });
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Error desconocido')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Información'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _userData == null
                  ? const Center(child: Text('No se encontraron datos del usuario'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoCard(
                            title: 'Información Personal',
                            items: [
                              EditableField(
                                label: 'Nombre',
                                value: _userData!['nombre'] ?? 'N/A',
                                onChanged: (nuevoValor) => _updateField('nombre', nuevoValor),
                              ),
                              EditableField(
                                label: 'Apellido',
                                value: _userData!['apellido'] ?? 'N/A',
                                onChanged: (nuevoValor) => _updateField('apellido', nuevoValor),
                              ),
                              EditableField(
                                label: 'Usuario',
                                value: _userData!['username'] ?? 'N/A',
                                onChanged: (nuevoValor) => _updateField('username', nuevoValor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildInfoCard(
                            title: 'Información de Contacto',
                            items: [
                              EditableField(
                                label: 'Email',
                                value: _userData!['email'] ?? 'N/A',
                                onChanged: (nuevoValor) => _updateField('email', nuevoValor),
                              ),
                              EditableField(
                                label: 'Teléfono',
                                value: _userData!['telefono'] ?? 'N/A',
                                isNumber: true,
                                onChanged: (nuevoValor) => _updateField('telefono', nuevoValor),
                              ),
                              EditableField(
                                label: 'Dirección',
                                value: _userData!['direccion'] ?? 'N/A',
                                onChanged: (nuevoValor) => _updateField('direccion', nuevoValor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildInfoCard(
                            title: 'Seguridad',
                            items: [
                              ListTile(
                                leading: const Icon(Icons.lock),
                                title: const Text('Contraseña'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                                    );
                                  },
                                ),
                                subtitle: const Text('********'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildInfoCard({required String title, required List<Widget> items}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...items,
          ],
        ),
      ),
    );
  }
}

class EditableField extends StatefulWidget {
  final String label;
  final String value;
  final bool isNumber;
  final Function(String) onChanged;

  const EditableField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.isNumber = false,
  });

  @override
  State<EditableField> createState() => _EditableFieldState();
}

class _EditableFieldState extends State<EditableField> {
  bool _editing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant EditableField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: _editing
          ? TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: widget.isNumber ? TextInputType.number : TextInputType.text,
              onSubmitted: (val) {
                widget.onChanged(val);
                setState(() => _editing = false);
              },
              onEditingComplete: () {
                widget.onChanged(_controller.text);
                setState(() => _editing = false);
              },
            )
          : GestureDetector(
              onTap: () => setState(() => _editing = true),
              child: Text(widget.value, style: const TextStyle(fontSize: 16)),
            ),
      leading: Icon(widget.isNumber ? Icons.phone : Icons.person),
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () => setState(() => _editing = true),
      ),
      subtitle: Text(widget.label),
    );
  }
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final result = await AuthService.changePasswordWithMessage(
      _currentController.text,
      _newController.text,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Error desconocido')),
      );
      if (result['success']) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cambiar Contraseña'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _currentController,
                obscureText: !_showCurrent,
                decoration: InputDecoration(
                  labelText: 'Contraseña Actual',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_showCurrent ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _showCurrent = !_showCurrent),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese su contraseña actual';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newController,
                obscureText: !_showNew,
                decoration: InputDecoration(
                  labelText: 'Nueva Contraseña',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_showNew ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _showNew = !_showNew),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese una nueva contraseña';
                  }
                  if (value.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmController,
                obscureText: !_showConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirmar Nueva Contraseña',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_showConfirm ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _showConfirm = !_showConfirm),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirme su nueva contraseña';
                  }
                  if (value != _newController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _changePassword,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Cambiar Contraseña'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}