import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:kohlberg/services/auth_service.dart';
import 'package:kohlberg/screens/product_list_screen.dart'; // Asumiendo que tienes una pantalla de lista de productos
import 'package:kohlberg/models/product.dart'; // Asumiendo que tienes un modelo de producto

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  final VoidCallback onOrderUpdated;

  const OrderDetailScreen({
    Key? key,
    required this.orderId,
    required this.onOrderUpdated,
  }) : super(key: key);

  @override
  _OrderDetailScreenState createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Map<String, dynamic>? _order;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _userIsActive = true; // Por defecto asumimos que está activo

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
    _checkUserStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkUserStatus(); // Vuelve a consultar el estado cada vez que cambia el contexto
  }

  Future<void> _checkUserStatus() async {
    final isActive = await AuthService.fetchUserIsActive();
    setState(() {
      _userIsActive = isActive;
    });
  }

  Future<void> _fetchOrderDetails() async {
    final token = await AuthService.getToken();
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/pedidos/${widget.orderId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _order = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al cargar los detalles del pedido')),
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

  Future<void> _updateProductQuantity(int detalleId, int newQuantity) async {
    if (newQuantity <= 0) return;

    final token = await AuthService.getToken();
    if (token == null) return;

    try {
      final response = await http.patch(
        Uri.parse('${AuthService.baseUrl}/detalle-pedido/$detalleId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'cantidad': newQuantity}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cantidad actualizada correctamente')),
        );
        await _fetchOrderDetails();
        widget.onOrderUpdated();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al actualizar la cantidad')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e')),
      );
    }
  }

  Future<void> _removeProduct(int detalleId) async {
    final token = await AuthService.getToken();
    if (token == null) return;

    try {
      final response = await http.delete(
        Uri.parse('${AuthService.baseUrl}/detalle-pedido/$detalleId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto eliminado del pedido')),
        );
        await _fetchOrderDetails();
        widget.onOrderUpdated();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar el producto')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e')),
      );
    }
  }

  Future<void> _addProductsToOrder(List<Product> selectedProducts) async {
    final token = await AuthService.getToken();
    if (token == null) return;

    final productos = selectedProducts.map((p) {
      return {
        'vino_id': p.id,
        'cantidad': 1, // Cantidad por defecto
      };
    }).toList();

    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/pedidos/${widget.orderId}/agregar-productos'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'productos': productos}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Productos agregados al pedido')),
        );
        await _fetchOrderDetails();
        widget.onOrderUpdated();
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorData['message'] ?? 'Error al agregar productos')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e')),
      );
    }
  }

  bool get _canEdit {
    return _order?['estado'] == 'pendiente' && _userIsActive;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles del Pedido #${widget.orderId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _checkUserStatus();
              await _fetchOrderDetails();
            },
            tooltip: 'Refrescar',
          ),
          if (_canEdit)
            IconButton(
              icon: Icon(_isEditing ? Icons.check : Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = !_isEditing;
                });
              },
            ),
        ],
      ),
      floatingActionButton: _canEdit
          ? FloatingActionButton(
              onPressed: () async {
                final selectedProducts = await Navigator.push<List<Product>>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductListScreen(
                      mode: 'select',
                      excludedProducts: _order?['productos']?.map<int>((p) => p['vino_id'] as int)?.toList(),
                    ),
                  ),
                );
                if (selectedProducts != null && selectedProducts.isNotEmpty) {
                  await _addProductsToOrder(selectedProducts);
                }
              },
              child: const Icon(Icons.add),
              backgroundColor: Colors.black,
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? const Center(child: Text('No se encontró el pedido'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOrderInfo(),
                      if (!_canEdit && _order?['estado'] != 'pendiente')
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            'Este pedido ya ha sido ${_order?['estado']} y no puede ser modificado',
                            style: const TextStyle(
                              color: Colors.red,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      if (!_canEdit && _userIsActive == false)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Text(
                            'Tu cuenta está inactiva, no puedes modificar pedidos',
                            style: TextStyle(
                              color: Colors.red,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      _buildProductsList(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildOrderInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pedido #${_order!['pedido_id']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Chip(
                  label: Text(
                    _order!['estado'] ?? 'pendiente',
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.black,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Fecha: ${_order!['fecha_pedido']}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Total: Bs. ${_order!['total']?.toStringAsFixed(2) ?? '0.00'}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsList() {
    final productos = _order!['productos'] as List<dynamic>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Productos:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...productos.map((product) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['vino_nombre'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Bs. ${product['precio_unitario']?.toStringAsFixed(2) ?? '0.00'} c/u',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    if (_isEditing && _canEdit)
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              final currentQty = product['cantidad'] as int;
                              if (currentQty > 1) {
                                _updateProductQuantity(
                                  product['detalle_id'],
                                  currentQty - 1,
                                );
                              }
                            },
                          ),
                          GestureDetector(
                            onTap: () => _showQuantityDialog(product),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                product['cantidad'].toString(),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              _updateProductQuantity(
                                product['detalle_id'],
                                product['cantidad'] + 1,
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Eliminar producto'),
                                  content: const Text(
                                      '¿Estás seguro de que quieres eliminar este producto del pedido?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        _removeProduct(product['detalle_id']);
                                      },
                                      child: const Text('Eliminar',
                                          style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      )
                    else
                      Text(
                        'x${product['cantidad']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Future<void> _showQuantityDialog(Map<String, dynamic> product) async {
    final quantityController = TextEditingController(text: product['cantidad'].toString());
    
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Editar cantidad de ${product['vino_nombre']}'),
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
                  _updateProductQuantity(product['detalle_id'], newQuantity);
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
}