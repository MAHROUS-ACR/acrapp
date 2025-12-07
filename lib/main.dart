import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import 'firebase_options.dart';

// ================= CART PROVIDER =================

class CartItem {
  final String id;
  final String name;
  final String image;
  final double price;
  final double? oldPrice;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    this.oldPrice,
    this.quantity = 1,
  });
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  List<CartItem> get items => _items;

  void addItem(CartItem item) {
    final index = _items.indexWhere((i) => i.id == item.id);

    if (index != -1) {
      _items[index].quantity++;
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  double get total =>
      _items.fold(0, (sum, i) => sum + (i.price * i.quantity));

  int get count =>
      _items.fold(0, (sum, i) => sum + i.quantity);
}

// ================= MAIN =================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: MaterialApp(
        title: 'متجري',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Cairo', useMaterial3: true),
        home: const MainScreen(),
      ),
    );
  }
}

// ================= MAIN SCREEN =================

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  final screens = [
    const StoreHomeScreen(),
    const Center(child: Text("الأقسام", style: TextStyle(fontSize: 24))),
    const CartScreen(),
    const Center(child: Text("حسابي", style: TextStyle(fontSize: 24))),
  ];

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => setState(() => currentIndex = i),
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
              icon: Icon(Icons.home), label: "الرئيسية"),
          const BottomNavigationBarItem(
              icon: Icon(Icons.category), label: "الأقسام"),

          BottomNavigationBarItem(
            icon: badges.Badge(
              badgeContent: Text(
                cart.count.toString(),
                style: const TextStyle(color: Colors.white),
              ),
              showBadge: cart.count > 0,
              child: const Icon(Icons.shopping_cart),
            ),
            label: "السلة",
          ),

          const BottomNavigationBarItem(
              icon: Icon(Icons.person), label: "حسابي"),
        ],
      ),
    );
  }
}

// ================= HOME SCREEN =================

class StoreHomeScreen extends StatefulWidget {
  const StoreHomeScreen({super.key});
  @override
  State<StoreHomeScreen> createState() => _StoreHomeScreenState();
}

class _StoreHomeScreenState extends State<StoreHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String activeCategory = "الكل";
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.blue, Colors.purple],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text("م",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "متجر",
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900),
                      ),
                      const Spacer(),
                      badges.Badge(
                        badgeContent: Text(
                          cart.count.toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                        showBadge: cart.count > 0,
                        child: IconButton(
                          icon: const Icon(Icons.shopping_cart),
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const CartScreen())),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => searchQuery = v),
                    decoration: InputDecoration(
                      hintText: "ابحث عن منتج...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // BODY
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("products")
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  var docs = snapshot.data!.docs;

                  Set<String> categories = {"الكل"};
                  for (var d in docs) {
                    var data = d.data() as Map<String, dynamic>;
                    if (data["category"] != null) {
                      categories.add(data["category"]);
                    }
                  }

                  var filtered = docs.where((d) {
                    var data = d.data() as Map<String, dynamic>;
                    var name =
                        (data["name"] ?? "").toString().toLowerCase();
                    var cat = (data["category"] ?? "");
                    return name.contains(searchQuery.toLowerCase()) &&
                        (activeCategory == "الكل" ||
                            cat == activeCategory);
                  }).toList();

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        // BANNER
                        Container(
                          margin: const EdgeInsets.all(16),
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: const DecorationImage(
                              image: NetworkImage(
                                  "https://via.placeholder.com/800x400/6B46C1/FFFFFF?text=خصم+50%"),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        // CATEGORIES
                        SizedBox(
                          height: 50,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: categories
                                .map((c) => Padding(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 6),
                                      child: ChoiceChip(
                                        label: Text(c),
                                        selected:
                                            activeCategory == c,
                                        onSelected: (_) =>
                                            setState(() =>
                                                activeCategory = c),
                                        selectedColor:
                                            Colors.deepPurple,
                                        labelStyle: TextStyle(
                                            color: activeCategory ==
                                                    c
                                                ? Colors.white
                                                : Colors.black),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),

                        // PRODUCT GRID
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics:
                                const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.72,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (context, i) {
                              var doc = filtered[i];
                              var data =
                                  doc.data() as Map<String, dynamic>;

                              return ProductCard(
                                productId: doc.id,
                                imageUrl: data["image"] ?? "",
                                title: data["name"] ?? "منتج",
                                price: (data["price"] ?? 0).toDouble(),
                                oldPrice: data["oldPrice"] != null
                                    ? (data["oldPrice"]).toDouble()
                                    : null,
                                discount: data["discount"]?.toString(),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= PRODUCT CARD =================

class ProductCard extends StatelessWidget {
  final String productId, imageUrl, title;
  final double price;
  final double? oldPrice;
  final String? discount;

  const ProductCard({
    super.key,
    required this.productId,
    required this.imageUrl,
    required this.title,
    required this.price,
    this.oldPrice,
    this.discount,
  });

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              if (discount != null)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "-$discount%",
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 2,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  if (oldPrice != null)
                    Text(
                      "$oldPrice ج.م",
                      style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                          fontSize: 12),
                    ),
                  Text(
                    "$price ج.م",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.deepPurple),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        cart.addItem(CartItem(
                          id: productId,
                          name: title,
                          image: imageUrl,
                          price: price,
                          oldPrice: oldPrice,
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("تمت الإضافة للسلة"),
                              duration: Duration(seconds: 1)),
                        );
                      },
                      icon: const Icon(Icons.add_shopping_cart, size: 18),
                      label: const Text("أضف للسلة"),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                ]),
          ),
        ],
      ),
    );
  }
}

// ================= CART SCREEN =================

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("سلة التسوق")),
      body: cart.items.isEmpty
          ? const Center(
              child: Text("السلة فارغة", style: TextStyle(fontSize: 20)))
          : ListView.builder(
              itemCount: cart.items.length,
              itemBuilder: (context, i) {
                final item = cart.items[i];

                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: item.image,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(item.name),
                  subtitle: Text(
                      "${item.price} ج.م × ${item.quantity}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => cart.removeItem(item.id),
                  ),
                );
              },
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.deepPurple,
        child: Text(
          "الإجمالي: ${cart.total.toStringAsFixed(2)} ج.م",
          style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}