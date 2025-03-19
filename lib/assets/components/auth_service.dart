import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Add this import

class AuthService {
  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    // Begin interactive sign in process
    final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();

    if (gUser == null) {
      throw Exception("Google sign in was canceled");
    }

    // Obtain auth details from request
    final GoogleSignInAuthentication gAuth = await gUser.authentication;

    // Create a new credential for user
    final credential = GoogleAuthProvider.credential(
      accessToken: gAuth.accessToken,
      idToken: gAuth.idToken,
    );

    // Finally, sign in
    return await FirebaseAuth.instance.signInWithCredential(credential);
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
      
      if (userDoc.exists && userDoc.get('isAdmin') == true) {
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
}