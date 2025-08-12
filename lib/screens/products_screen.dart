import 'package:flutter/material.dart';
import 'package:kohlberg/services/auth_service.dart';
import 'package:kohlberg/screens/product_detail_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:kohlberg/services/cart_service.dart';
import 'package:kohlberg/services/favorite_service.dart';
import 'package:provider/provider.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> with RouteAware {
  List<dynamic> categories = [];
  List<dynamic> products = [];
  List<dynamic> filteredProducts = [];
  bool isLoading = true;
  String? selectedCategoryId;
  String searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchProducts();
    Provider.of<FavoriteService>(context, listen: false).fetchUserFavorites();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Suscribirse al RouteObserver
    ModalRoute.of(context)?.addScopedWillPopCallback(_onWillPop);
    // Recargar productos cada vez que la pantalla es visible
    _fetchProducts();
  }

  Future<bool> _onWillPop() async {
    // Para limpiar el callback al salir de la pantalla
    ModalRoute.of(context)?.removeScopedWillPopCallback(_onWillPop);
    return true;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = _searchController.text;
      _filterProducts();
    });
  }

  void _filterProducts() {
    if (searchQuery.isEmpty && selectedCategoryId == null) {
      filteredProducts = List.from(products);
    } else {
      filteredProducts = products.where((product) {
        final matchesSearch = product['nombre']
            .toString()
            .toLowerCase()
            .contains(searchQuery.toLowerCase());
        final matchesCategory = selectedCategoryId == null ||
            product['categoria_id'].toString() == selectedCategoryId;
        return matchesSearch && matchesCategory;
      }).toList();
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/categorias'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          categories = jsonDecode(response.body);
        });
      } else {
        print('Error al cargar categorías: ${response.statusCode}');
      }
    } catch (e) {
      print('Error de conexión: $e');
    }
  }

  Future<void> _fetchProducts() async {
    try {
      final token = await AuthService.getToken();
      final url = '${AuthService.baseUrl}/vinos';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          products = jsonDecode(response.body);
          filteredProducts = List.from(products);
          isLoading = false;
          _filterProducts();
        });
      } else {
        print('Error al cargar productos: ${response.statusCode}');
        if (!mounted) return;
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error de conexión: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar productos...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          // Selector de categorías
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButtonFormField<String>(
              value: selectedCategoryId,
              hint: const Text('Todas las categorías'),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Todas las categorías'),
                ),
                ...categories.map((category) {
                  return DropdownMenuItem(
                    value: category['categoria_id'].toString(),
                    child: Text(category['nombre']),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  selectedCategoryId = value;
                  _filterProducts();
                });
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Lista de productos
          Expanded(
            child: _buildProductsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    final favoriteService = Provider.of<FavoriteService>(context);
    
    if (isLoading || favoriteService.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
  
    if (filteredProducts.isEmpty) {
      return const Center(
        child: Text(
          'No hay productos disponibles',
          style: TextStyle(fontSize: 16),
        ),
      );
    }
  
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        final isFavorite = favoriteService.isProductFavorite(product);
        
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailScreen(product: product),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomRight: Radius.circular(12),
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
                            product['nombre'],
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
                            'Bs. ${product['precio'].toString()}',
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
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ProductDetailScreen(product: product),
                                      ),
                                    );
                                  },
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
                                    // Aquí va tu lógica normal para agregar al carrito
                                    Provider.of<CartService>(context, listen: false).addToCart(product);
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
              // Botón de favorito
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.grey,
                    size: 30,
                  ),
                  onPressed: () => favoriteService.toggleFavorite(product),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}