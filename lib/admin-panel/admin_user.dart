import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

  Future<void> deleteUser(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.red.shade700,
        title: Container(
          child: Text(
            'Manage Users',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No users found'));
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
                  return await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm Delete'),
                      content: const Text('Are you sure you want to delete this user?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) async {
                  await deleteUser(uid);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('User $email deleted')),
                  );
                },
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  color: Colors.white,
                  child: ListTile(
                    leading: Icon(
                      role == 'admin' ? Icons.shield_outlined : Icons.account_circle,
                      color: role == 'admin' ? Colors.red.shade700 : Colors.grey.shade700,
                    ),
                    title: Text(
                      email,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Role: $role',
                      style: TextStyle(
                        color: role == 'admin' ? Colors.red.shade700 : Colors.black87,
                      ),
                    ),
                    trailing: DropdownButton<String>(
                      value: role,
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: Colors.black),
                      items: ['user', 'admin'].map((r) {
                        return DropdownMenuItem(
                          value: r,
                          child: Text(
                            r,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: r == 'admin' ? Colors.red.shade700 : Colors.black,
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
              );
            },
          );
        },
      ),
    );
  }
}
