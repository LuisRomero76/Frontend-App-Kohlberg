// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

class AuthService {
  static const String baseUrl = 'https://backend-kohlberg.onrender.com'; 
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static String? lastErrorMessage;

  // Métodos para manejar el token JWT
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  static Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }

  // Métodos para manejar datos del usuario
  static Future<void> saveUserData(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userKey, jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString(userKey);
    return userString != null ? jsonDecode(userString) : null;
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString(userKey);
    if (userString != null) {
      final userData = jsonDecode(userString);
      return userData['persona_id'] as int?;
    }
    return null;
  }

  static Future<void> deleteUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(userKey);
  }

  // Registro de usuario mejorado
  static Future<bool> register({
    required String nombre,
    required String apellido,
    required String username,
    required String telefono,
    required String direccion,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/usuarios'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'apellido': apellido,
          'username': username,
          'telefono': telefono,
          'direccion': direccion,
          'email': email,
          'password_hash': password,
        }),
      );

      if (response.statusCode == 201) {
        // Si el registro es exitoso, hacer login automáticamente
        final loginResponse = await http.post(
          Uri.parse('$baseUrl/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'password': password,
          }),
        );

        if (loginResponse.statusCode == 200) {
          final data = jsonDecode(loginResponse.body);
          await saveToken(data['token']);
          await saveUserData(data['usuario']);
          return true;
        }
      }

      // Manejo de errores del backend
      final errorData = jsonDecode(response.body);
      lastErrorMessage = errorData['message'] ?? 'Error en el registro';
      return false;
    } catch (e) {
      lastErrorMessage = 'Error de conexión: $e';
      return false;
    }
  }

  // Login con email y contraseña
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await saveToken(responseData['token']);
        await saveUserData(responseData['usuario']); // Asegúrate que esto incluya persona_id
        return {'success': true};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Credenciales inválidas'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e'
      };
    }
  }

  // Login con Google (pendiente de corrección)
  static Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        clientId: '', // Opcional: solo si usas servidor de autenticación
        forceCodeForRefreshToken: true, // Forzar selección de cuenta
      );

      // Cerrar sesión existente primero
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return {
          'success': false,
        };
      }

      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      final response = await http.post(
        Uri.parse('$baseUrl/google-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': googleAuth.idToken}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        await saveToken(responseData['token']);
        await saveUserData(responseData['usuario']);
        return {'success': true};
      } else {
        return {
          'success': false,
        };
      }
    } catch (e) {
      return {
        'success': false,
      };
    }
  }
  // Cerrar sesión
  static Future<bool> logout() async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      await deleteToken();
      await deleteUserData();

      return response.statusCode == 200;
    } catch (e) {
      lastErrorMessage = 'Error al cerrar sesión: $e';
      return false;
    }
  }

  // Verificar autenticación
  static Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey) != null;
  }

  // Recuperación de contraseña
  static Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/usuarios/solicitar-codigo'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {'success': true, 'message': responseData['message']};
      } else {
        return {'success': false, 'message': responseData['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  static Future<Map<String, dynamic>> verifyResetCode(String email, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/usuarios/verificar-codigo'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'codigo': code}),
      );
  
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true, 
          'persona_id': responseData['persona_id'] // Cambiado de usuario_id a persona_id
        };
      } else {
        return {'success': false, 'message': responseData['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  static Future<Map<String, dynamic>> resetPassword(String userId, String newPassword) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/usuarios/reset-contra/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'password': newPassword}),
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {'success': true, 'message': responseData['message']};
      } else {
        return {'success': false, 'message': responseData['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  static Future<bool> fetchUserIsActive() async {
    final token = await getToken();
    if (token == null) return false;

    final response = await http.get(
      Uri.parse('$baseUrl/usuario/estado'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Ajusta el campo según tu backend, por ejemplo: data['estado'] == 1
      return data['estado'] == 1;
    }
    return false;
  }

  static Future<Map<String, dynamic>> updateUserFieldWithMessage(String field, String value) async {
    final userId = await getUserId();
    final token = await getToken();
    if (userId == null || token == null) {
      return {'success': false, 'message': 'No autenticado.'};
    }

    final response = await http.patch(
      Uri.parse('$baseUrl/usuarios/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({field: value}),
    );

    final data = jsonDecode(response.body);
    return {
      'success': response.statusCode == 200,
      'message': data['message'] ?? 'Error desconocido'
    };
  }

  static Future<Map<String, dynamic>> changePasswordWithMessage(String currentPassword, String newPassword) async {
    final userId = await getUserId();
    final token = await getToken();
    if (userId == null || token == null) {
      return {'success': false, 'message': 'No autenticado.'};
    }

    final response = await http.patch(
      Uri.parse('$baseUrl/usuarios/$userId/password'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    final data = jsonDecode(response.body);
    return {
      'success': response.statusCode == 200,
      'message': data['message'] ?? 'Error desconocido'
    };
  }

  static Future<Map<String, dynamic>> uploadProfilePhoto(File imageFile) async {
    final userId = await getUserId();
    final token = await getToken();
    if (userId == null || token == null) {
      return {'success': false, 'message': 'No autenticado.'};
    }

    final uri = Uri.parse('$baseUrl/usuarios/$userId/foto');
    final request = http.MultipartRequest('PATCH', uri)
      ..headers['Authorization'] = 'Bearer $token';

    final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
    final file = await http.MultipartFile.fromPath(
      'foto',
      imageFile.path,
      contentType: MediaType.parse(mimeType),
    );
    request.files.add(file);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body);

    return {
      'success': response.statusCode == 200,
      'message': data['message'] ?? 'Error desconocido',
      'perfil_user': data['perfil_user']
    };
  }

  static Future<Map<String, dynamic>?> fetchUserFromBackend() async {
    final token = await getToken();
    if (token == null) {
      print('No hay token');
      return null;
    }

    final parts = token.split('.');
    if (parts.length != 3) {
      print('Token mal formado');
      return null;
    }
    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final decoded = jsonDecode(payload);
    print('Payload del token: $decoded');
    final userId = decoded['userId'] ?? decoded['persona_id'] ?? decoded['id'];
    print('userId extraído del token: $userId');
    if (userId == null) {
      print('No se pudo extraer el userId');
      return null;
    }

    final response = await http.get(
      Uri.parse('$baseUrl/usuarios/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    print('Status code backend: ${response.statusCode}');
    print('Respuesta backend: ${response.body}');
    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);
      await saveUserData(userData);
      return userData;
    }
    return null;
  }
}