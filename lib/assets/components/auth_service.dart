import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Add this import
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:engineering_project/assets/components/email_service.dart';

class AuthService {
  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      // Create a new provider
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      
      // Add scopes
      googleProvider.addScope('https://www.googleapis.com/auth/userinfo.email');
      googleProvider.addScope('https://www.googleapis.com/auth/userinfo.profile');
      
      // Once signed in, return the UserCredential
      final userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
      
      // Create/update user document in Firestore
      if (userCredential.user != null) {
        print('Web Google Sign-In successful - User: ${userCredential.user?.email}');
        print('Web User Display Name: ${userCredential.user?.displayName}');
        print('Web User Provider Data: ${userCredential.user?.providerData}');
        
        // Get email from provider data if user.email is null
        String? email = userCredential.user?.email;
        if (email == null || email.isEmpty) {
          for (var info in userCredential.user!.providerData) {
            if (info.email != null && info.email!.isNotEmpty) {
              email = info.email;
              break;
            }
          }
        }
        
        if (email == null || email.isEmpty) {
          throw Exception("Failed to get user email from Google Sign-In");
        }
        
        // Create a temporary user with the correct email
        final tempUser = userCredential.user!;
        await _createOrUpdateUserDocument(tempUser);
      }
      
      return userCredential;
    } else {
      // Begin interactive sign in process for mobile
      final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();

      if (gUser == null) {
        throw Exception("Google sign in was canceled");
      }

      print('Mobile Google Sign-In Account: ${gUser.email}');
      print('Mobile User Display Name: ${gUser.displayName}');

      // Obtain auth details from request
      final GoogleSignInAuthentication gAuth = await gUser.authentication;

      // Create a new credential for user
      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      // Finally, sign in
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      // Create/update user document in Firestore
      if (userCredential.user != null) {
        print('Mobile Firebase Auth successful - User: ${userCredential.user?.email}');
        print('Mobile User Display Name: ${userCredential.user?.displayName}');
        print('Mobile User Provider Data: ${userCredential.user?.providerData}');
        
        // Get email from provider data if user.email is null
        String? email = userCredential.user?.email;
        if (email == null || email.isEmpty) {
          for (var info in userCredential.user!.providerData) {
            if (info.email != null && info.email!.isNotEmpty) {
              email = info.email;
              break;
            }
          }
        }
        
        if (email == null || email.isEmpty) {
          throw Exception("Failed to get user email from Google Sign-In");
        }
        
        // Create a temporary user with the correct email
        final tempUser = userCredential.user!;
        await _createOrUpdateUserDocument(tempUser);
      }
      
      return userCredential;
    }
  }

  // Helper method to create or update user document
  Future<void> _createOrUpdateUserDocument(User user) async {
    // Get email from provider data if user.email is null
    String? email = user.email;
    if (email == null || email.isEmpty) {
      for (var info in user.providerData) {
        if (info.email != null && info.email!.isNotEmpty) {
          email = info.email;
          break;
        }
      }
    }

    if (email == null || email.isEmpty) {
      print('Warning: Attempting to create/update user document with empty email');
      return;
    }

    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get();

    final userData = {
      'uid': user.uid,
      'email': email.toLowerCase().trim(),
      'name': user.displayName?.split(' ').first ?? '',
      'surname': user.displayName?.split(' ').last ?? '',
      'profileImageUrl': user.photoURL ?? '',
      'role': 'user',
      'lastLogin': FieldValue.serverTimestamp(),
    };

    print('Creating/Updating user document with data: $userData');

    if (!docSnapshot.exists) {
      // Create new user document
      await userDoc.set({
        ...userData,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create wallet for new user
      await FirebaseFirestore.instance.collection('wallets').doc(user.uid).set({
        'balance': 0.0,
        'created_at': FieldValue.serverTimestamp(),
      });

      // Send welcome email
      try {
        await EmailService.sendWelcomeEmail(
          userEmail: email,
          userName: userData['name']?.toString() ?? 'User',
          userId: user.uid,
        );
      } catch (e) {
        print('Error sending welcome email: $e');
        // Don't throw the error as the account was already created successfully
      }
    } else {
      // Update existing user document
      await userDoc.update(userData);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
  }

  // Check if user is admin
  Future<bool> isUserAdmin() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      // Option 1: Using Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (userDoc.exists && userDoc.get('role') == 'admin') {
        return true;
      }
      
      // Option 2: You can also check specific email addresses during development
      if (user.email == "admin@example.com") {
        return true;
      }
      
      // Option 3: For a more secure approach, use custom claims (uncomment if you're using this)
      /*
      // Force refresh token to get latest claims
      await user.getIdToken(true);
      final idTokenResult = await user.getIdTokenResult();
      return idTokenResult.claims?['admin'] == true;
      */
      
      return false;
    } catch (e) {
      print("Error checking admin status: $e");
      return false;
    }
  }

  // Create user with admin flag in Firestore (for new registrations)
  Future<void> createUserRecord(User user, {bool isAdmin = false}) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({
          'email': user.email,
          'isAdmin': isAdmin,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)); // Merge in case the document already exists
  }

  // Migration function to update existing user documents
  Future<void> migrateExistingUsers() async {
    try {
      print('Starting user migration...');
      
      // Get all users from Firestore
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      
      for (var doc in usersSnapshot.docs) {
        final userData = doc.data();
        final userId = doc.id;
        
        print('Migrating user: $userId');
        
        // Get the user from Firebase Auth
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          print('No authenticated user found. Please sign in first.');
          return;
        }
        
        // Update the user document with the new structure
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'uid': userId,
          'email': userData['email'] ?? user.email ?? '',
          'name': userData['name'] ?? user.displayName?.split(' ').first ?? '',
          'surname': userData['surname'] ?? user.displayName?.split(' ').last ?? '',
          'profileImageUrl': userData['profileImageUrl'] ?? user.photoURL ?? '',
          'role': userData['role'] ?? 'user',
          'lastLogin': FieldValue.serverTimestamp(),
        });
        
        // Check if wallet exists, if not create it
        final walletDoc = await FirebaseFirestore.instance.collection('wallets').doc(userId).get();
        if (!walletDoc.exists) {
          await FirebaseFirestore.instance.collection('wallets').doc(userId).set({
            'balance': 0.0,
            'created_at': FieldValue.serverTimestamp(),
          });
        }
        
        print('Successfully migrated user: $userId');
      }
      
      print('User migration completed successfully!');
    } catch (e) {
      print('Error during user migration: $e');
      rethrow;
    }
  }

  // Helper function to check if a user needs migration
  Future<bool> needsMigration(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (!userDoc.exists) return true;
      
      final userData = userDoc.data()!;
      return !userData.containsKey('uid') || 
             !userData.containsKey('name') || 
             !userData.containsKey('surname');
    } catch (e) {
      print('Error checking migration status: $e');
      return true;
    }
  }

  // Function to migrate a single user
  Future<void> migrateSingleUser(String userId) async {
    try {
      print('Starting migration for user: $userId');
      
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        print('User document not found: $userId');
        return;
      }
      
      final userData = userDoc.data()!;
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        print('No authenticated user found. Please sign in first.');
        return;
      }
      
      // Update the user document
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'uid': userId,
        'email': userData['email'] ?? user.email ?? '',
        'name': userData['name'] ?? user.displayName?.split(' ').first ?? '',
        'surname': userData['surname'] ?? user.displayName?.split(' ').last ?? '',
        'profileImageUrl': userData['profileImageUrl'] ?? user.photoURL ?? '',
        'role': userData['role'] ?? 'user',
        'lastLogin': FieldValue.serverTimestamp(),
      });
      
      // Check and create wallet if needed
      final walletDoc = await FirebaseFirestore.instance.collection('wallets').doc(userId).get();
      if (!walletDoc.exists) {
        await FirebaseFirestore.instance.collection('wallets').doc(userId).set({
          'balance': 0.0,
          'created_at': FieldValue.serverTimestamp(),
        });
      }
      
      print('Successfully migrated user: $userId');
    } catch (e) {
      print('Error migrating user $userId: $e');
      rethrow;
    }
  }
}