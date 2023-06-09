import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Интернет магазин',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class DatabaseHelper {
  static Future<Database> database() async {
    final dbPath = await getDatabasesPath();
    final dbFilePath = path.join(dbPath, 'shop.db');

    return openDatabase(
      dbFilePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE products(id INTEGER PRIMARY KEY, title TEXT, description TEXT)');
        await db.execute('CREATE TABLE cart(id INTEGER PRIMARY KEY, title TEXT, description TEXT)');
      },
    );
  }

  static Future<void> insertProduct(Product product) async {
    final db = await database();
    await db.insert(
      'products',
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Product>> getProducts() async {
    final db = await database();
    final List<Map<String, dynamic>> productMaps = await db.query('products');
    return List.generate(productMaps.length, (index) {
      return Product.fromMap(productMaps[index]);
    });
  }

  static Future<void> insertCartItem(Product product) async {
    final db = await database();
    await db.insert(
      'cart',
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Product>> getCartItems() async {
    final db = await database();
    final List<Map<String, dynamic>> cartMaps = await db.query('cart');
    return List.generate(cartMaps.length, (index) {
      return Product.fromMap(cartMaps[index]);
    });
  }

  static Future<void> removeCartItem(int id) async {
    final db = await database();
    await db.delete(
      'cart',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> updateProduct(Product product) async {
    final db = await database();
    await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  static Future<void> removeProduct(int id) async {
    final db = await database();
    await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

class Product {
  final int id;
  final String title;
  final String description;

  Product({
    required this.id,
    required this.title,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
    };
  }

  static Product fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      title: map['title'],
      description: map['description'],
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Интернет магазин'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image.network(
            //   'https://example.com/shop_logo.png',
            //   width: 200,
            //   height: 200,
            //   fit: BoxFit.contain,
            // ),
            const SizedBox(height: 20),
            const Text(
              'Добро пожаловать в наш магазин!',
              style: TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
      drawer: AppDrawer(),
    );
  }
}

class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          ListTile(
            title: const Text('Список товаров'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProductListPage()),
              );
            },
          ),
          ListTile(
            title: const Text('Товары'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProductPage()),
              );
            },
          ),
          ListTile(
            title: const Text('Корзина'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartPage()),
              );
            },
          ),
          ListTile(
            title: const Text('Оплата'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PaymentPage()),
              );
            },
          ),
          ListTile(
            title: const Text('Доставка'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DeliveryPage()),
              );
            },
          ),
          ListTile(
            title: const Text('О нас'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AboutPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ProductListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Список товаров'),
      ),
      body: FutureBuilder<List<Product>>(
        future: DatabaseHelper.getProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return const Center(
              child: Text('Ошибка при загрузке товаров'),
            );
          } else if (snapshot.hasData) {
            final List<Product> products = snapshot.data!;
            return ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(products[index].title),
                  subtitle: Text(products[index].description),
                  trailing: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      DatabaseHelper.insertCartItem(products[index]);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Товар добавлен в корзину'),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          } else {
            return const Center(
              child: Text('Нет доступных товаров'),
            );
          }
        },
      ),
    );
  }
}

class ProductPage extends StatefulWidget {
  @override
  _ProductPageState createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  List<Product> products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    DatabaseHelper.getProducts().then((loadedProducts) {
      setState(() {
        products = loadedProducts;
      });
    });
  }

  void _navigateToEditProductPage(Product product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductPage(product: product),
      ),
    );
    _loadProducts();
  }

  void _deleteProduct(Product product) {
    DatabaseHelper.removeProduct(product.id).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Товар удален'),
        ),
      );
      _loadProducts(); // Обновляем список товаров
    });
  }

  void refreshProductPage() {
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Список товаров'),
      ),
      body: ProductList(
        products: products,
        onEditProduct: _navigateToEditProductPage,
        onDeleteProduct: _deleteProduct,
      ),
      floatingActionButton: FloatingActionButton(
  child: Icon(Icons.add),
  onPressed: () => _navigateToEditProductPage(Product(id: 0, title: '', description: '')),
),
    );
  }
}

class ProductList extends StatelessWidget {
  final List<Product> products;
  final Function(Product) onEditProduct;
  final Function(Product) onDeleteProduct;

  const ProductList({
    Key? key,
    required this.products,
    required this.onEditProduct,
    required this.onDeleteProduct,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ListTile(
          title: Text(product.title),
          subtitle: Text(product.description),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () => onEditProduct(product),
              ),
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () => onDeleteProduct(product),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AddProductPage extends StatefulWidget {
  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить товар'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Название'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите название товара';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Описание'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите описание товара';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                child: const Text('Добавить'),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final product = Product(
                      id: DateTime.now().millisecondsSinceEpoch,
                      title: _titleController.text,
                      description: _descriptionController.text,
                    );
                    DatabaseHelper.insertProduct(product).then((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Товар добавлен'),
                        ),
                      );
                      Navigator.pop(context);
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditProductPage extends StatefulWidget {
  final Product product;

  const EditProductPage({Key? key, required this.product}) : super(key: key);

  @override
  _EditProductPageState createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.product.title;
    _descriptionController.text = widget.product.description;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveProduct() {
  final String title = _titleController.text.trim();
  final String description = _descriptionController.text.trim();

  if (title.isNotEmpty && description.isNotEmpty) {
    final Product updatedProduct = Product(
      id: widget.product.id,
      title: title,
      description: description,
    );

    DatabaseHelper.updateProduct(updatedProduct).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Товар обновлен'),
        ),
      );
      Navigator.pop(context);
    });
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Пожалуйста, заполните все поля'),
      ),
    );
  }
}


  void _deleteProduct() {
    DatabaseHelper.removeProduct(widget.product.id).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Товар удален'),
        ),
      );
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Редактирование товара'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Название',
              ),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Описание',
              ),
            ),
            SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  child: Text('Сохранить'),
                  onPressed: _saveProduct,
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(primary: Colors.red),
                  child: Text('Удалить'),
                  onPressed: _deleteProduct,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late Future<List<Product>> cartItemsFuture;

  @override
  void initState() {
    super.initState();
    cartItemsFuture = DatabaseHelper.getCartItems();
  }

  void refreshPage() {
    setState(() {});
  }

  void refreshCart() {
    setState(() {
      // Обновление данных корзины
      DatabaseHelper.getCartItems().then((cartItems) {
    setState(() {
      cartItemsFuture = Future.value(cartItems);
    });
  });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Корзина'),
      ),
      body: FutureBuilder<List<Product>>(
        future: cartItemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return const Center(
              child: Text('Ошибка при загрузке товаров'),
            );
          } else if (snapshot.hasData) {
            final List<Product> cartItems = snapshot.data!;
            return ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(cartItems[index].title),
                  subtitle: Text(cartItems[index].description),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      DatabaseHelper.removeCartItem(cartItems[index].id).then((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Товар удален из корзины'),
                          ),
                        );
                        refreshCart(); // Обновление корзины после удаления товара
                      });
                    },
                  ),
                );
              },
            );
          } else {
            return const Center(
              child: Text('Корзина пуста'),
            );
          }
        },
      ),
    );
  }
}

class PaymentPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Оплата'),
      ),
      body: const Center(
        child: Text('Страница оплаты'),
      ),
    );
  }
}

class DeliveryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Доставка'),
      ),
      body: const Center(
        child: Text('Страница доставки'),
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('О нас'),
      ),
      body: const Center(
        child: Text('Страница "О нас"'),
      ),
    );
  }
}
