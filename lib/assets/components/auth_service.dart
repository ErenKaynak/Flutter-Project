import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _firebaseauth = FirebaseAuth.instance;

  //get current user
  User? getCurrentUser() {
    return _firebaseauth.currentUser;
  }

  //Email Sign in
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      //sign user in
      UserCredential userCredential = await _firebaseauth
          .signInWithEmailAndPassword(email: email, password: password);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  //Email Sign up
  Future<UserCredential> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    //create a new user
    try {
      UserCredential userCredential = await _firebaseauth
          .createUserWithEmailAndPassword(email: email, password: password);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  //sign out
  Future<void> signOut() async {
    return await _firebaseauth.signOut();
  }

  //google sign in
  signInWithGoogle() async {
    //begin interactive sign in process
    final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();

    //user cancels sign in process
    if (gUser == null) return;

    //obtain auth details from request
    final GoogleSignInAuthentication gAuth = await gUser!.authentication;

    //create a new credential for user
    final credential = GoogleAuthProvider.credential(
      accessToken: gAuth.accessToken,
      idToken: gAuth.idToken,
    );

    //sign in user with the credential
    return await _firebaseauth.signInWithCredential(credential);
  }

  //possible error messages
  String getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'Exception: wrong-password':
        return 'Password is incorrect.';
      case 'Exception: no-user-found':
        return 'No user found.';
      case 'Exception: invalid-email':
        return 'This email does not exist.';
      //add others if needed
      default:
        return 'An Unexpected error occurred. Try again later.';
    }
  }
}
