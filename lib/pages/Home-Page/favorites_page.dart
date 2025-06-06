import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:engineering_project/pages/product-detail-page.dart';
import 'package:engineering_project/pages/theme_notifier.dart';
import 'package:provider/provider.dart';

class FavoritesPage extends StatefulWidget {
  final Function onFavoritesChanged;

  FavoritesPage({required this.onFavoritesChanged});

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<Map<String, dynamic>> favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFavorites();
  }

  Future<void> fetchFavorites() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          favorites = [];
          _isLoading = false;
        });
        return;
      }

      final favoritesSnapshot = await FirebaseFirestore.instance
          .collection('favorites')
          .doc(user.uid)
          .collection('userFavorites')
          .get();

      final List<Map<String, dynamic>> loadedFavorites = [];
      favoritesSnapshot.docs.forEach((doc) {
        final data = doc.data();
        loadedFavorites.add({
          'id': doc.id,
          'name': data['name'] ?? 'Unknown Product',
          'price': data['price']?.toString() ?? '0',
          'image': data['image'] ?? 'lib/assets/Images/placeholder.png',
          'category': data['category'] ?? 'Uncategorized',
          'description': data['description'] ?? 'No description available',
          'stock': data['stock'] ?? 0,
        });
      });

      setState(() {
        favorites = loadedFavorites;
        _isLoading = false;
      });
    } catch (error) {
      print('Error fetching favorites: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> removeFromFavorites(String productId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('favorites')
          .doc(user.uid)
          .collection('userFavorites')
          .doc(productId)
          .delete();

      setState(() {
        favorites.removeWhere((product) => product['id'] == productId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed from favorites'),
          duration: Duration(seconds: 2),
        ),
      );

      widget.onFavoritesChanged();
    } catch (e) {
      print('Error removing from favorites: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove from favorites'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      appBar: AppBar(title: Text('My Favorites')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : favorites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 70, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        "No favorites yet",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Items you favorite will appear here",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(10),
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final product = favorites[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: (product["image"].startsWith('http') ||
                                  product["image"].startsWith('https'))
                              ? Image.network(
                                  product["image"],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'lib/assets/Images/placeholder.png',
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                )
                              : Image.asset(
                                  product["image"],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.image_not_supported,
                                      size: 30,
                                    );
                                  },
                                ),
                        ),
                        title: Text(
                          product["name"],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("₺${product["price"]}"),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.favorite,
                            color: themeNotifier.isBlackMode
                                ? Theme.of(context).colorScheme.secondary
                                : Colors.red,
                          ),
                          onPressed: () => removeFromFavorites(product["id"]),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProductDetailPage(productId: product["id"]),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
} 