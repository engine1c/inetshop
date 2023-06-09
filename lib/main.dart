import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';

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
        await db.execute('CREATE TABLE products(id INTEGER PRIMARY KEY, title TEXT, description TEXT,quantity INTEGER)');
        await db.execute('CREATE TABLE cart(id INTEGER PRIMARY KEY, title TEXT, description TEXT,quantity INTEGER)');
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

    var value = {

      'id': product.id,
      'title': product.title,
      'description': product.description,      
     'quantity': product.quantity+=1,
   };   
   await db.insert(
       'cart',
      value,
      //product.toMap(),
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

  static Future<void> updateCart(Product product) async {
    final db = await database();
    await db.update(
      'cart',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
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
  int quantity;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'quantity': quantity,
    };
  }

  static Product fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      title: map['title']??'',
      description: map['description']??'',
      quantity: map['quantity'],
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
          children: const [
            // Image.network(
            //   'https://example.com/shop_logo.png',
            //   width: 200,
            //   height: 200,
            //   fit: BoxFit.contain,
            // ),
            SizedBox(height: 20),
            Text(
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
            title: const Text('Главная'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProductListPage()),
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
            title: const Text('Справочник Товары'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProductPage()),
              );
            },
          ),          ListTile(
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
        title: const Text('Выбор товаров'),
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
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(products[index].description),
                      Text('Quantity: ${products[index].quantity}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      Product updatedProduct = products[index];
                      //updatedProduct.quantity += 1;
                      DatabaseHelper.insertCartItem(updatedProduct).then((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Товар добавлен в корзину'),
                          ),
                        );
                      });
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
  void _navigateToAddProductPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductPage(),
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
        title: const Text('Справочник ТОВАРОВ'),
      ),
      body: ProductList(
        products: products,
        onEditProduct: _navigateToEditProductPage,
        onDeleteProduct: _deleteProduct,
      ),
      floatingActionButton: FloatingActionButton(
  child: const Icon(Icons.add),
  onPressed: () => _navigateToAddProductPage(), 
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
          //title: Text(product.title),
          title: Column(
                      children: [
                        const Divider(),
                        Row(children: [
                          Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Text(':'),
                                      const SizedBox(width: 5),
                                      Text(product.title),
                                    ],
                                  )
                                ],
                              )
                              ),
                      ]
                      ),
                          Row(children: [Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Text(':'),
                                      const SizedBox(width: 5),
                                      Text((product.description)),
                                    ],
                                  )
                                ],
                              )),
                        ]
                        ),
                      ],
                    ),
          subtitle: Column(
                      children: [
                        const Divider(),
                        Row(children: [
                          Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Text('Кількість:'),
                                      const SizedBox(width: 5),
                                      Text(product.quantity .toString()),
                                    ],
                                  )
                                ],
                              )),
                          Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Text('Ціна:'),
                                      const SizedBox(width: 5),
                                      Text((product.quantity .toString())),
                                    ],
                                  )
                                ],
                              )),
                        ]),
                      ],
                    ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => onEditProduct(product),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => onDeleteProduct(product),
              ),
            ],
          ),
        );
      },
    );
  }
}

doubleThreeToString(double sum) {
  var f = NumberFormat("##0", "en_US");
  return (f.format(sum).toString());
}

class AddProductPage extends StatefulWidget {
  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _quantityController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();    
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
              TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'quantity**'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введите Количество товара';
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
                      quantity: int.tryParse(_quantityController.text )  ?? 0,
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
 final TextEditingController _quantityController = TextEditingController() ;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.product.title;
    _descriptionController.text = widget.product.description; 
    _quantityController.text = widget.product.quantity.toString();
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

  final String quantity = _quantityController.text.trim();

  if (title.isNotEmpty && description.isNotEmpty) {
    final Product updatedProduct = Product(
      id: widget.product.id,
      title: title,
      description: description,
      quantity: int.tryParse(quantity )  ?? 0,
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
              decoration: const InputDecoration(
                labelText: 'Название',
              ),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание',
              ),
            ),
                        TextField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Количество',
              ),
            ),
            SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  child: const Text('Сохранить'),
                  onPressed: _saveProduct,
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(primary: Colors.red),
                  child: const Text('Удалить'),
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
    setState(() {
      cartItemsFuture = DatabaseHelper.getCartItems();
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
              child: Text('Ошибка при загрузке товаров из корзины'),
            );
          } else if (snapshot.hasData) {
            final List<Product> cartItems = snapshot.data!;
            return ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(cartItems[index].title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cartItems[index].description),
                      Text('Кво: ${cartItems[index].quantity}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_shopping_cart),
                    onPressed: () {
                      Product updatedProduct = cartItems[index];
                      updatedProduct.quantity -= 1;
                      if (updatedProduct.quantity <= 0) {
                        DatabaseHelper.removeCartItem(updatedProduct.id ).then((_) {
                          refreshPage();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Товар удален из корзины'),
                            ),
                          );
                        });
                      } else {
                        DatabaseHelper.updateCart(updatedProduct).then((_) {
                          refreshPage();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Количество товара в корзине обновлено'),
                            ),
                          );
                        }
                        );
                      }
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
