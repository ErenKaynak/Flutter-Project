import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:provider/provider.dart';
import '../pages/theme_notifier.dart';
import 'package:engineering_project/l10n/app_localizations.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await fetchUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading users: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final usersSnapshot = await _firestore.collection('users').get();
    final users = usersSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'uid': doc.id,
        'email': data['email'] ?? '',
        'role': data['role'] ?? 'user',
        'disabled': data['disabled'] ?? false,
        'disabledAt': data['disabledAt'],
        'disabledBy': data['disabledBy'],
      };
    }).toList();

    users.sort((a, b) {
      if (a['role'] == b['role']) return 0;
      if (a['role'] == 'admin') return -1;
      return 1;
    });

    return users;
  }

  Future<void> updateUserRole(String uid, String newRole) async {
    await _firestore.collection('users').doc(uid).update({'role': newRole});
    await _loadUsers();
  }

  Future<bool> checkAdminStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        print('Checking admin status for user: ${user.email}');
        print('User data from Firestore: ${userDoc.data()}');
        
        // Check for 'role' field instead of 'isAdmin'
        return userDoc.data()?['role'] == 'admin';
      }
      return false;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  Future<void> deleteUser(String uid) async {
    try {
      // Check admin status
      final isAdmin = await checkAdminStatus();
      if (!isAdmin) {
        throw Exception('Admin authentication required');
      }

      // Get admin credentials
      final adminUser = FirebaseAuth.instance.currentUser;
      if (adminUser == null) {
        throw Exception('Admin not authenticated');
      }

      // Start a batch write for Firestore operations
      final batch = FirebaseFirestore.instance.batch();

      // Delete user's data from various collections
      batch.delete(_firestore.collection('users').doc(uid));
      batch.delete(_firestore.collection('cart').doc(uid));
      batch.delete(_firestore.collection('favorites').doc(uid));

      // Get user's orders
      final ordersQuery = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: uid)
          .get();
      
      // Add order deletions to batch
      for (var doc in ordersQuery.docs) {
        batch.delete(doc.reference);
      }

      // Execute all Firestore deletions
      await batch.commit();

      // Delete from Authentication
      final adminCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: adminUser.email!,
        password: 'ADMIN_PASSWORD', // You'll need to handle this securely
      );

      // Create a new instance for the user to be deleted
      final userToDelete = FirebaseAuth.instanceFor(app: FirebaseAuth.instance.app)
          .currentUser;

      // Delete the user from Authentication
      await userToDelete?.delete();

      // Sign back in as admin
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: adminUser.email!, password: 'ADMIN_PASSWORD');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User successfully deleted'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      setState(() {});
    } catch (e) {
      print('Error in deleteUser: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> toggleUserStatus(String uid, bool currentStatus) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore.collection('users').doc(uid).update({
        'disabled': !currentStatus,
        'disabledAt': !currentStatus ? FieldValue.serverTimestamp() : null,
        'disabledBy': !currentStatus ? currentUser.uid : null,
      });
      await _loadUsers();
    } catch (e) {
      print('Error toggling user status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.isDarkMode;
    final themeColor = themeNotifier.isSpecialModeActive 
        ? themeNotifier.getThemeColor(themeNotifier.specialTheme)
        : Colors.red;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(l10n.userManagement),
        backgroundColor: themeColor,
        elevation: isDark ? 0 : 2,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: themeColor,
              ),
            )
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                final isAdmin = user['role'] == 'admin';
                final isDisabled = user['disabled'] ?? false;

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: isDark ? 2 : 1,
                  color: isDark ? Colors.grey[900] : Colors.white,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isAdmin ? themeColor : Colors.grey,
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      user['email'] ?? 'No email',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        decoration: isDisabled ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Text(
                      'Role: ${user['role']}',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Role change button
                        IconButton(
                          icon: Icon(
                            Icons.admin_panel_settings,
                            color: isAdmin ? themeColor : Colors.grey,
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: isDark ? Colors.grey[900] : Colors.white,
                                title: Text(
                                  'Change Role',
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      title: Text(
                                        'Admin',
                                        style: TextStyle(
                                          color: isDark ? Colors.white : Colors.black,
                                        ),
                                      ),
                                      leading: Icon(Icons.admin_panel_settings),
                                      onTap: () {
                                        updateUserRole(user['uid'], 'admin');
                                        Navigator.pop(context);
                                      },
                                    ),
                                    ListTile(
                                      title: Text(
                                        'User',
                                        style: TextStyle(
                                          color: isDark ? Colors.white : Colors.black,
                                        ),
                                      ),
                                      leading: Icon(Icons.person),
                                      onTap: () {
                                        updateUserRole(user['uid'], 'user');
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        // Disable/Enable button
                        IconButton(
                          icon: Icon(
                            isDisabled ? Icons.lock : Icons.lock_open,
                            color: isDisabled ? Colors.red : themeColor,
                          ),
                          onPressed: () => toggleUserStatus(user['uid'], isDisabled),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
