class Product {
  final int id;
  final String nombre;
  final double precio;
  final String? imagenUrl;
  final String? descripcion;
  final int? categoriaId;

  Product({
    required this.id,
    required this.nombre,
    required this.precio,
    this.imagenUrl,
    this.descripcion,
    this.categoriaId,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['vino_id'],
      nombre: json['nombre'],
      precio: double.tryParse(json['precio'].toString()) ?? 0.0,
      imagenUrl: json['imagen_url'],
      descripcion: json['descripcion'],
      categoriaId: json['categoria_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vino_id': id,
      'nombre': nombre,
      'precio': precio,
      'imagen_url': imagenUrl,
      'descripcion': descripcion,
      'categoria_id': categoriaId,
    };
  }
}