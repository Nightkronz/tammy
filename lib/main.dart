import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class Product {
  String id;
  String name;
  double price;
  int discountPercent; // 0..100
  String? imageBase64;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.discountPercent = 0,
    this.imageBase64,
  });

  double get discountedPrice => price * (1 - discountPercent / 100);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'discountPercent': discountPercent,
        'imageBase64': imageBase64,
      };

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'],
        name: j['name'],
        price: (j['price'] as num).toDouble(),
        discountPercent: j['discountPercent'] ?? 0,
        imageBase64: j['imageBase64'],
      );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Tammy',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Product> _products = [];
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('products');
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      _products.clear();
      _products.addAll(list.map((e) => Product.fromJson(e)));
    }
    setState(() => _loading = false);
  }

  Future<void> _saveProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_products.map((p) => p.toJson()).toList());
    await prefs.setString('products', raw);
  }

  void _openEditor({Product? product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: ProductEditor(
          product: product,
          onSave: (p) async {
            if (product != null) {
              final idx = _products.indexWhere((x) => x.id == product.id);
              if (idx != -1) _products[idx] = p;
            } else {
              _products.add(p);
            }
            await _saveProducts();
            setState(() {});
            Navigator.of(ctx).pop();
          },
        ),
      ),
    );
  }

  void _deleteProduct(Product p) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Eliminar producto'),
            content: const Text('¿Seguro que quieres eliminar este producto?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
              TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Eliminar')),
            ],
          ),
        ) ??
        false;
    if (ok) {
      _products.removeWhere((x) => x.id == p.id);
      await _saveProducts();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _products.where((p) => p.name.toLowerCase().contains(_query.toLowerCase())).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar...'),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(child: Text('No hay productos'))
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final p = filtered[i];
                          return ListTile(
                            leading: p.imageBase64 != null
                                ? CircleAvatar(backgroundImage: MemoryImage(base64Decode(p.imageBase64!)))
                                : const CircleAvatar(child: Icon(Icons.shopping_bag)),
                            title: Text(p.name),
                            subtitle: p.discountPercent > 0
                                ? Text.rich(TextSpan(children: [
                                    TextSpan(text: '\$${p.discountedPrice.toStringAsFixed(2)}  ', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    TextSpan(text: '\$${p.price.toStringAsFixed(2)}', style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)),
                                  ]))
                                : Text('\$${p.price.toStringAsFixed(2)}'),
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'edit') _openEditor(product: p);
                                if (v == 'del') _deleteProduct(p);
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'edit', child: Text('Editar')),
                                const PopupMenuItem(value: 'del', child: Text('Eliminar')),
                              ],
                            ),
                            onTap: () => _openEditor(product: p),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ProductEditor extends StatefulWidget {
  final Product? product;
  final void Function(Product) onSave;

  const ProductEditor({super.key, this.product, required this.onSave});

  @override
  State<ProductEditor> createState() => _ProductEditorState();
}

class _ProductEditorState extends State<ProductEditor> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameC;
  late TextEditingController _priceC;
  late TextEditingController _discountC;
  String? _imageBase64;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameC = TextEditingController(text: p?.name ?? '');
    _priceC = TextEditingController(text: p != null ? p.price.toStringAsFixed(2) : '0.00');
    _discountC = TextEditingController(text: p != null ? p.discountPercent.toString() : '0');
    _imageBase64 = p?.imageBase64;
  }

  @override
  void dispose() {
    _nameC.dispose();
    _priceC.dispose();
    _discountC.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (file != null) {
      final bytes = await File(file.path).readAsBytes();
      setState(() => _imageBase64 = base64Encode(bytes));
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final id = widget.product?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final name = _nameC.text.trim();
    final price = double.tryParse(_priceC.text.replaceAll(',', '.')) ?? 0.0;
    final discount = int.tryParse(_discountC.text) ?? 0;
    final p = Product(id: id, name: name, price: price, discountPercent: discount.clamp(0, 100), imageBase64: _imageBase64);
    widget.onSave(p);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: _imageBase64 != null
                    ? Image.memory(base64Decode(_imageBase64!), height: 120, width: 120, fit: BoxFit.cover)
                    : Container(
                        height: 120,
                        width: 120,
                        color: Colors.grey[200],
                        child: const Icon(Icons.add_a_photo, size: 40),
                      ),
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _nameC, decoration: const InputDecoration(labelText: 'Nombre'), validator: (v) => (v ?? '').isEmpty ? 'Requerido' : null),
              TextFormField(controller: _priceC, decoration: const InputDecoration(labelText: 'Precio'), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) => (double.tryParse((v ?? '').replaceAll(',', '.')) == null) ? 'Número inválido' : null),
              TextFormField(controller: _discountC, decoration: const InputDecoration(labelText: 'Descuento (%)'), keyboardType: TextInputType.number, validator: (v) {
                final n = int.tryParse(v ?? '0') ?? 0;
                if (n < 0 || n > 100) return '0-100';
                return null;
              }),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _save, child: const Text('Guardar')),
            ],
          ),
        ),
      ),
    );
  }
}
