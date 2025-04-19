import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    setState(() {});
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
      final userToDelete = FirebaseAuth.instance.app.options.androidClientId != null
          ? FirebaseAuth.instanceFor(app: FirebaseAuth.instance.app)
          : FirebaseAuth.instance;

      // Delete the user from Authentication
      await userToDelete.currentUser?.delete();

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

  // Add this method to handle the disable confirmation dialog
  Future<void> _showDisableConfirmationDialog(String uid, String email, bool currentlyDisabled) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          currentlyDisabled ? 'Enable Account' : 'Disable Account',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          currentlyDisabled 
            ? 'Are you sure you want to enable ${email}\'s account?'
            : 'Are you sure you want to disable ${email}\'s account?\nThis will prevent the user from logging in.',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              currentlyDisabled ? 'Enable' : 'Disable',
              style: TextStyle(
                color: currentlyDisabled ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Update the toggleUserAccount method
  Future<void> toggleUserAccount(String uid, String email, bool disable) async {
    try {
      // Show confirmation dialog
      final confirmed = await _showDisableConfirmationDialog(uid, email, !disable);

      final isAdmin = await checkAdminStatus();
      if (!isAdmin) {
        throw Exception('Admin authentication required');
      }

      // Update user status in Firestore
      await _firestore.collection('users').doc(uid).update({
        'disabled': disable,
        'disabledAt': disable ? FieldValue.serverTimestamp() : null,
        'disabledBy': FirebaseAuth.instance.currentUser?.email,
        'disabledReason': disable ? 'Administrative action' : null,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                disable ? Icons.block : Icons.check_circle,
                color: Colors.white,
              ),
              SizedBox(width: 8),
              Text('Account ${disable ? 'disabled' : 'enabled'} successfully'),
            ],
          ),
          backgroundColor: disable ? Colors.red : Colors.green,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      setState(() {});
    } catch (e) {
      print('Error toggling user account: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text(
          'Manage Users',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: isDark ? 0 : 2,
        iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            padding: EdgeInsets.all(16.0),
            margin: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [Colors.red.shade900, Colors.grey.shade900]
                    : [Colors.red.shade300, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.red.shade900 : Colors.red.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.people_alt_outlined,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "User Management",
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.grey[400] : Colors.black54,
                        ),
                      ),
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: fetchUsers(),
                        builder: (context, snapshot) {
                          return Text(
                            "${snapshot.data?.length ?? 0} Users",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Users List
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).primaryColor,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 60,
                          color: isDark ? Colors.red.shade400 : Colors.red,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Error: ${snapshot.error}',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 60,
                          color: isDark ? Colors.grey.shade600 : Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No users found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final users = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final uid = user['uid'];
                    final email = user['email'];
                    final role = user['role'];

                    return Dismissible(
                      key: Key(uid),
                      direction: DismissDirection.endToStart,
                      background: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          color: Colors.red.shade700,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        final shouldDelete = await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Theme.of(context).cardColor,
                            title: Text(
                              'Confirm Delete',
                              style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
                            ),
                            content: Text(
                              'Are you sure you want to delete this user?',
                              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: Text('Cancel',
                                  style: TextStyle(color: Theme.of(context).primaryColor),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: Text('Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (shouldDelete == true) {
                          await deleteUser(uid);
                          return true;
                        }
                        return false;
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: isDark
                              ? BorderSide(color: Colors.grey.shade800, width: 1)
                              : BorderSide.none,
                        ),
                        elevation: isDark ? 1 : 4,
                        color: Theme.of(context).cardColor,
                        child: ListTile(
                          leading: Icon(
                            role == 'admin' ? Icons.shield_outlined : Icons.account_circle,
                            color: role == 'admin'
                                ? (isDark ? Colors.red.shade400 : Colors.red.shade700)
                                : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                          ),
                          title: Text(
                            email,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.titleMedium?.color,
                            ),
                          ),
                          subtitle: Text(
                            'Role: $role',
                            style: TextStyle(
                              color: role == 'admin'
                                  ? (isDark ? Colors.red.shade400 : Colors.red.shade700)
                                  : Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  user['disabled'] == true 
                                    ? Icons.block 
                                    : Icons.check_circle_outline,
                                  color: user['disabled'] == true 
                                    ? Colors.red 
                                    : Colors.green,
                                ),
                                tooltip: user['disabled'] == true 
                                  ? 'Enable Account' 
                                  : 'Disable Account',
                                onPressed: () => toggleUserAccount(
                                  uid, 
                                  email, 
                                  !(user['disabled'] == true)
                                ),
                              ),
                              DropdownButton<String>(
                                value: role,
                                dropdownColor: Theme.of(context).cardColor,
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                                items: ['user', 'admin'].map((r) {
                                  return DropdownMenuItem(
                                    value: r,
                                    child: Text(
                                      r,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: r == 'admin'
                                            ? (isDark ? Colors.red.shade400 : Colors.red.shade700)
                                            : Theme.of(context).textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (newRole) {
                                  if (newRole != null && newRole != role) {
                                    updateUserRole(uid, newRole);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
