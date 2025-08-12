import 'package:flutter/material.dart';
import 'package:kohlberg/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FavoriteService extends ChangeNotifier {
  List<dynamic> _favorites = [];
  bool _isLoading = false;

  List<dynamic> get favorites => _favorites;
  bool get isLoading => _isLoading;

  Future<void> fetchUserFavorites() async {
    try {
      final token = await AuthService.getToken();
      final userData = await AuthService.getUserData();
      
      if (userData == null || token == null) return;

      _isLoading = true;
      notifyListeners();

      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/favoritos/persona/${userData['persona_id']}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _favorites = jsonDecode(response.body);
      } else {
        print('Error al cargar favoritos: ${response.statusCode}');
      }
    } catch (e) {
      print('Error de conexión al obtener favoritos: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(dynamic product) async {
    try {
      final token = await AuthService.getToken();
      final userData = await AuthService.getUserData();
      
      if (userData == null || token == null) return;

      final isFavorite = _favorites.any((fav) => fav['vino_id'] == product['vino_id']);
      final url = isFavorite
          ? '${AuthService.baseUrl}/favoritos/${_getFavoriteId(product)}'
          : '${AuthService.baseUrl}/favoritos';

      final response = isFavorite
          ? await http.delete(
              Uri.parse(url),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
            )
          : await http.post(
              Uri.parse(url),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'persona_id': userData['persona_id'],
                'vino_id': product['vino_id'],
              }),
            );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchUserFavorites();
      } else {
        print('Error al ${isFavorite ? 'eliminar' : 'agregar'} favorito: ${response.statusCode}');
      }
    } catch (e) {
      print('Error de conexión al favorito: $e');
    }
  }

  String _getFavoriteId(dynamic product) {
    final favorite = _favorites.firstWhere(
      (fav) => fav['vino_id'] == product['vino_id'],
      orElse: () => {'favorito_id': ''},
    );
    return favorite['favorito_id'].toString();
  }

  bool isProductFavorite(dynamic product) {
    return _favorites.any((fav) => fav['vino_id'] == product['vino_id']);
  }

  void clearFavorites() {
    _favorites = [];
    notifyListeners();
  }
}