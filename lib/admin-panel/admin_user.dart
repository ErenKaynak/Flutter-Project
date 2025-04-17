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
      print('Starting delete process for user: $uid');
      final isAdmin = await checkAdminStatus();
      print('Admin status check result: $isAdmin');

      if (!isAdmin) {
        throw Exception('Admin authentication required');
      }

      final functions = FirebaseFunctions.instanceFor(
        region: 'us-central1',
        app: Firebase.app(),
      );
      
      print('Calling deleteUserCompletely function...');
      final callable = functions.httpsCallable(
        'deleteUserCompletely',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 30),
        ),
      );
      
      final result = await callable.call({'uid': uid});
      print('Function response: ${result.data}');
      
      if (result.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User successfully deleted'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        setState(() {});
      }
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
                          trailing: Theme(
                            data: Theme.of(context).copyWith(
                              dropdownMenuTheme: DropdownMenuThemeData(
                                textStyle: TextStyle(
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                            child: DropdownButton<String>(
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
