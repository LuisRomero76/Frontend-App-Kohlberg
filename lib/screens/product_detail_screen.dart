import 'package:flutter/material.dart';
import 'package:kohlberg/services/auth_service.dart';
import 'package:kohlberg/services/cart_service.dart';
import 'package:kohlberg/services/favorite_service.dart';
import 'package:provider/provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final dynamic product;

  const ProductDetailScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {

  @override
  void initState() {
    super.initState();
    Provider.of<FavoriteService>(context, listen: false).fetchUserFavorites();
  }

  @override
  Widget build(BuildContext context) {
    final favoriteService = Provider.of<FavoriteService>(context);
    final isFavorite = favoriteService.isProductFavorite(widget.product);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product['nombre']),
        actions: [
          IconButton(
            icon: favoriteService.isLoading
                ? const CircularProgressIndicator()
                : Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : null,
                  ),
            onPressed: favoriteService.isLoading 
                ? null 
                : () => favoriteService.toggleFavorite(widget.product),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen principal del producto - Centrada
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: widget.product['imagen_url'] != null
                    ? Image.network(
                        '${AuthService.baseUrl}/assets/vinos/${widget.product['imagen_url']}',
                        height: 300,
                        fit: BoxFit.contain,
                      )
                    : Container(
                        height: 300,
                        width: 300,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.wine_bar, size: 100, color: Colors.grey),
                        ),
                      ),
              ),
            ),
            // Detalles del producto
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product['nombre'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Bs. ${widget.product['precio'].toString()}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Descripción',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.product['descripcion'] ?? 'No hay descripción disponible',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  // Información adicional
                  _buildDetailRow('Categoría', widget.product['categoria_id']?.toString() ?? 'N/A'),
                  const SizedBox(height: 30),
                  // Botón de añadir al carrito
                  SizedBox(
                    width: double.infinity,
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
                        Provider.of<CartService>(context, listen: false).addToCart(widget.product);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Producto agregado al carrito')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Añadir al carrito',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}