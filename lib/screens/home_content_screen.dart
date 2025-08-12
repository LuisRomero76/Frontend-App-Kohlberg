import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:kohlberg/services/auth_service.dart';
import 'package:kohlberg/screens/product_detail_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:kohlberg/services/cart_service.dart';
import 'package:kohlberg/services/favorite_service.dart';
import 'package:provider/provider.dart';

class HomeContentScreen extends StatefulWidget {
  const HomeContentScreen({Key? key}) : super(key: key);

  @override
  State<HomeContentScreen> createState() => _HomeContentScreenState();
}

class _HomeContentScreenState extends State<HomeContentScreen> {
  int _currentCarouselIndex = 0;
  List<dynamic> categories = [];
  List<dynamic> products = [];
  bool isLoading = true;
  String? selectedCategoryId;

  final List<String> _carouselImages = [
    'carrusel1.jpg',
    'carrusel2.jpg',
    'carrusel3.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchProducts();
    Provider.of<FavoriteService>(context, listen: false).fetchUserFavorites();
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

  Future<void> _fetchProducts({String? categoryId}) async {
    try {
      final token = await AuthService.getToken();
      final url = categoryId != null
          ? '${AuthService.baseUrl}/vinos/categoria/$categoryId'
          : '${AuthService.baseUrl}/vinos';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          products = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        print('Error al cargar productos: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error de conexión: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String _getImageTitle(String imageName) {
    switch (imageName) {
      case 'carrusel1.jpg':
        return 'Trabajamos día a dia';
      case 'carrusel2.jpg':
        return 'Trabajamos con pasión';
      case 'carrusel3.jpg':
        return 'Trabajamos con los mejores';
      default:
        return 'Oferta Especial';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Carrusel de imágenes
            _buildImageCarousel(),
            // Indicadores del carrusel
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _carouselImages.asMap().entries.map((entry) {
                return Container(
                  width: 8.0,
                  height: 8.0,
                  margin: const EdgeInsets.symmetric(
                      vertical: 10.0, horizontal: 4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black.withOpacity(
                            _currentCarouselIndex == entry.key ? 0.9 : 0.4),
                  ),
                );
              }).toList(),
            ),
            // Sección de categorías
            _buildCategoriesSection(),
            // Sección de productos
            _buildProductsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel() {
    return CarouselSlider(
      options: CarouselOptions(
        height: 200.0,
        autoPlay: true,
        enlargeCenterPage: true,
        aspectRatio: 16 / 9,
        autoPlayCurve: Curves.fastOutSlowIn,
        enableInfiniteScroll: true,
        autoPlayAnimationDuration: const Duration(milliseconds: 2000),
        viewportFraction: 0.8,
        onPageChanged: (index, reason) {
          setState(() {
            _currentCarouselIndex = index;
          });
        },
      ),
      items: _carouselImages.map((imageName) {
        return Builder(
          builder: (BuildContext context) {
            return Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.symmetric(horizontal: 5.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                image: DecorationImage(
                  image: NetworkImage(
                    '${AuthService.baseUrl}/assets/vinos/$imageName',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getImageTitle(imageName),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildCategoriesSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('Categorias', style: TextStyle(fontSize: 23),),
              ),
              Expanded(child: Divider(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategoryId = category['categoria_id'].toString(); // Convertir a String
                      isLoading = true;
                    });
                    _fetchProducts(categoryId: category['categoria_id'].toString()); // Convertir a String
                  },
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      color: selectedCategoryId == category['categoria_id'].toString()
                          ? Colors.blue.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wine_bar, size: 40),
                        const SizedBox(height: 5),
                        Text(
                          category['nombre'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProductsSection() {
    final favoriteService = Provider.of<FavoriteService>(context);
    
    if (isLoading || favoriteService.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
  
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectedCategoryId != null
                ? 'Productos de la categoría seleccionada'
                : 'Todos los productos',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
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
                        // Sección derecha - Imagen del producto
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
                    // Botón de favorito en la esquina superior derecha
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
          ),
        ],
      ),
    );
  }
}