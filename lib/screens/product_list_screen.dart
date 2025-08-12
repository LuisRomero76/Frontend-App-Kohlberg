import 'package:flutter/material.dart';
import 'package:kohlberg/models/product.dart';
import 'package:kohlberg/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProductListScreen extends StatefulWidget {
  final String mode; // 'select' o 'view'
  final List<int>? excludedProducts;

  const ProductListScreen({
    Key? key,
    required this.mode,
    this.excludedProducts,
  }) : super(key: key);

  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Product> _products = [];
  List<Product> _selectedProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    final token = await AuthService.getToken();
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/vinos'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _products = data.map((json) => Product.fromJson(json)).toList();
          
          // Filtrar productos excluidos si es necesario
          if (widget.excludedProducts != null) {
            _products.removeWhere((p) => widget.excludedProducts!.contains(p.id));
          }
          
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al cargar los productos')),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de conexión: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        actions: [
          if (widget.mode == 'select')
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                Navigator.pop(context, _selectedProducts);
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const Center(child: Text('No hay productos disponibles'))
              : ListView.builder(
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    final isSelected = _selectedProducts.contains(product);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: product.imagenUrl != null
                            ? Image.network(
                                '${AuthService.baseUrl}/assets/vinos/${product.imagenUrl}',
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.wine_bar),
                        title: Text(product.nombre),
                        subtitle: Text('Bs. ${product.precio.toStringAsFixed(2)}'),
                        trailing: widget.mode == 'select'
                            ? Checkbox(
                                value: isSelected,
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedProducts.add(product);
                                    } else {
                                      _selectedProducts.remove(product);
                                    }
                                  });
                                },
                              )
                            : null,
                        onTap: widget.mode == 'select'
                            ? () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedProducts.remove(product);
                                  } else {
                                    _selectedProducts.add(product);
                                  }
                                });
                              }
                            : null,
                      ),
                    );
                  },
                ),
    );
  }
}