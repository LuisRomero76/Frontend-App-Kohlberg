// profile_screen.dart
import 'package:flutter/material.dart';
import 'package:kohlberg/services/auth_service.dart';
import 'package:kohlberg/screens/login_screen.dart';
import 'package:kohlberg/screens/orders_screen.dart';
import 'package:kohlberg/screens/user_info_screen.dart';
import 'package:kohlberg/services/cart_service.dart';
import 'package:kohlberg/services/favorite_service.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final data = await AuthService.fetchUserFromBackend();
    if (mounted) {
      setState(() {
        _userData = data;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    final cart = Provider.of<CartService>(context, listen: false);
    final favorites = Provider.of<FavoriteService>(context, listen: false);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final success = await AuthService.logout();
      Navigator.of(context).pop(); // Cerrar el diálogo de carga
      
      if (success && context.mounted) {
        cart.clearCart(); // Limpiar el carrito al cerrar sesión
        favorites.clearFavorites(); // Limpiar favoritos al cerrar sesión
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cerrar sesión')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (result == true) {
      await _logout(context);
    }
  }

  Widget _buildProfilePhoto() {
    final photoFile = _userData?['perfil_user'];
    final photoUrl = (photoFile != null && photoFile.isNotEmpty)
        ? '${AuthService.baseUrl}/assets/perfil_users/$photoFile'
        : null;
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey[200],
          backgroundImage: (photoUrl != null) ? NetworkImage(photoUrl) : null,
          child: (photoUrl == null)
              ? const Icon(Icons.person, size: 50, color: Colors.grey)
              : null,
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.camera_alt),
          label: const Text('Cambiar foto'),
          onPressed: _pickAndUploadPhoto,
        ),
      ],
    );
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final result = await AuthService.uploadProfilePhoto(file);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Error desconocido')),
      );
      if (result['success']) {
        setState(() {
          _userData!['perfil_user'] = result['perfil_user'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        centerTitle: true,
      ),
      body: _userData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Sección de información del usuario
                  _buildUserHeader(),
                  
                  // Opciones del perfil
                  _buildProfileOptions(context),
                ],
              ),
            ),
    );
  }

  Widget _buildUserHeader() {
    if (_userData == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildProfilePhoto(),
          const SizedBox(height: 16),
          Text(
            '${_userData!['nombre'] ?? ''} ${_userData!['apellido'] ?? ''}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _userData!['email'] ?? '',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOptions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildProfileOption(
            icon: Icons.shopping_bag,
            title: 'Mis Pedidos',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OrdersScreen()),
              );
            },
          ),
          const Divider(height: 1),
          _buildProfileOption(
            icon: Icons.person,
            title: 'Mi Información',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserInfoScreen()),
              );
            },
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _confirmLogout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Cerrar Sesión',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}