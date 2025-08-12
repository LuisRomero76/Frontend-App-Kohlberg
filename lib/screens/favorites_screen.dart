import 'package:flutter/material.dart';
import 'package:kohlberg/services/auth_service.dart';
import 'package:kohlberg/screens/product_detail_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:kohlberg/services/cart_service.dart';
import 'package:kohlberg/services/favorite_service.dart';
import 'package:provider/provider.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<dynamic> completeProducts = [];
  bool isLoading = true;
  late FavoriteService _favoriteService; // <-- Agrega esta línea

  @override
  void initState() {
    super.initState();
    _favoriteService = Provider.of<FavoriteService>(context, listen: false); // <-- Inicializa aquí
    _fetchFavoritesWithDetails();
    _favoriteService.addListener(_onFavoritesChanged);
  }

  @override
  void dispose() {
    _favoriteService.removeListener(_onFavoritesChanged); // <-- Usa la referencia guardada
    super.dispose();
  }

  void _onFavoritesChanged() {
    // Actualizar la lista cuando cambien los favoritos
    _fetchFavoritesWithDetails();
  }

  Future<void> _fetchFavoritesWithDetails() async {
    try {
      setState(() => isLoading = true);
      
      final token = await AuthService.getToken();
      
      if (token == null) {
        setState(() => isLoading = false);
        return;
      }

      final List<dynamic> productsWithDetails = [];
      
      for (var favorite in _favoriteService.favorites) {
        final response = await http.get(
          Uri.parse('${AuthService.baseUrl}/vinos/${favorite['vino_id']}'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final productDetails = jsonDecode(response.body);
          productsWithDetails.add(Map<String, dynamic>.from(favorite)..addAll(productDetails));
        }
      }

      setState(() {
        completeProducts = productsWithDetails;
        isLoading = false;
      });
    } catch (e) {
      print('Error de conexión: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _removeFavorite(dynamic favorite) async {
    try {
      await _favoriteService.toggleFavorite(favorite);
    } catch (e) {
      print('Error de conexión al eliminar favorito: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar favorito')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Favoritos'),
      ),
      body: _buildFavoritesList(),
    );
  }

  Widget _buildFavoritesList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
  
    if (completeProducts.isEmpty) {
      return const Center(
        child: Text(
          'No tienes productos favoritos',
          style: TextStyle(fontSize: 16),
        ),
      );
    }
  
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: completeProducts.length,
      itemBuilder: (context, index) {
        final product = completeProducts[index];
        
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
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
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagen del producto
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      onTap: () => _navigateToProductDetail(product),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                        child: product['imagen_url'] != null
                            ? Image.network(
                                '${AuthService.baseUrl}/assets/vinos/${product['imagen_url']}',
                                width: 100,
                                height: 200,
                                fit: BoxFit.contain,
                                alignment: Alignment.center,
                              )
                            : Container(
                                height: 200,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(Icons.wine_bar,
                                      size: 50, color: Colors.grey),
                                ),
                              ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nombre del producto
                          Text(
                            product['nombre'] ?? product['vino_nombre'] ?? 'Producto sin nombre',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Descripción
                          Text(
                            product['descripcion'] ?? 'Vino Premium',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 16),
                          // Precio
                          Text(
                            'Bs. ${product['precio']?.toStringAsFixed(2) ?? '0.00'}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Botones
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _navigateToProductDetail(product),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.black),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: const Text(
                                    'Ver producto',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final isActive = await AuthService.fetchUserIsActive();
                                    if (!isActive) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Tu cuenta está inactiva. No puedes agregar productos al carrito.')),
                                        );
                                      }
                                      return;
                                    }
                                    Provider.of<CartService>(context, listen: false).addToCart(product); // <--- sin await
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Producto agregado al carrito')),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: const Text('Añadir al carrito'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Botón para quitar de favoritos
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: const Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: 30,
                  ),
                  onPressed: () => _removeFavorite(product),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToProductDetail(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    );
  }
}