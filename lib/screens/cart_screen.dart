// cart_screen.dart
import 'package:flutter/material.dart';
import 'package:kohlberg/services/auth_service.dart';
import 'package:kohlberg/services/cart_service.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isLoading = false;

  Future<void> _placeOrder(BuildContext context) async {
    final cart = Provider.of<CartService>(context, listen: false);
    final userData = await AuthService.getUserData();
    final token = await AuthService.getToken();

    if (userData == null || token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para realizar un pedido')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final productos = cart.cartItems.map((item) {
        return {
          'vino_id': item['vino_id'],
          'cantidad': item['cantidad'],
        };
      }).toList();

      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/pedidos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'persona_id': userData['persona_id'],
          'productos': productos,
        }),
      );

      if (response.statusCode == 201) {
        cart.clearCart();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pedido realizado con éxito')),
        );
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al realizar el pedido: ${errorData['message']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showEditQuantityDialog(BuildContext context, Map<String, dynamic> item, CartService cart) async {
    final quantityController = TextEditingController(text: item['cantidad'].toString());
    
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Editar cantidad de ${item['nombre']}'),
          content: TextField(
            controller: quantityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Cantidad',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final newQuantity = int.tryParse(quantityController.text) ?? 1;
                if (newQuantity > 0) {
                  cart.updateQuantity(item['vino_id'], newQuantity);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('La cantidad debe ser mayor a 0')),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrito'),
        actions: [
          if (cart.itemCount > 0)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Vaciar carrito'),
                    content: const Text('¿Estás seguro de que quieres vaciar todo el carrito?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          cart.clearCart();
                          Navigator.pop(context);
                        },
                        child: const Text('Vaciar', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              tooltip: 'Vaciar carrito',
            ),
        ],
      ),
      body: Column(
        children: [
          if (cart.itemCount == 0)
            const Expanded(
              child: Center(
                child: Text('Tu carrito está vacío', style: TextStyle(fontSize: 18)),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: cart.itemCount,
                itemBuilder: (context, index) {
                  final item = cart.cartItems[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          item['imagen_url'] != null
                              ? Image.network(
                                  '${AuthService.baseUrl}/assets/vinos/${item['imagen_url']}',
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.contain,
                                  alignment: Alignment.center,
                                )
                              : Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.wine_bar),
                                ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['nombre'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Bs. ${item['precio'].toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  if (item['cantidad'] > 1) {
                                    cart.updateQuantity(
                                      item['vino_id'],
                                      item['cantidad'] - 1,
                                    );
                                  }
                                },
                              ),
                              GestureDetector(
                                onTap: () => _showEditQuantityDialog(context, item, cart),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item['cantidad'].toString(),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  cart.updateQuantity(
                                    item['vino_id'],
                                    item['cantidad'] + 1,
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Eliminar producto'),
                                      content: Text('¿Quieres eliminar ${item['nombre']} del carrito?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Cancelar'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            cart.removeFromCart(item['vino_id']);
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          if (cart.itemCount > 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:', style: TextStyle(fontSize: 18)),
                      Text(
                        'Bs. ${cart.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () async {
                        final isActive = await AuthService.fetchUserIsActive();
                        if (!isActive) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Tu cuenta está inactiva. No puedes realizar pedidos.')),
                            );
                          }
                          return;
                        }
                        // Aquí va tu lógica normal para realizar el pedido
                        await _placeOrder(context); // <--- Cambia esto
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Realizar Pedido',
                              style: TextStyle(fontSize: 18),
                            ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}