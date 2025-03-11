import 'package:engineering_project/pages/register_page.dart';
import 'package:engineering_project/pages/root_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:engineering_project/assets/components/auth_service.dart';
import 'package:engineering_project/assets/components/square_tile.dart';
import 'package:engineering_project/pages/forget_pw_page.dart';

class LoginPage extends StatefulWidget {
  LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool passToggle = true;

  String? emailError;
  String? passwordError;

  void signUserIn() async {
    setState(() {
      emailError = null;
      passwordError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Dismiss the loading indicator
      if (context.mounted) Navigator.pop(context);
      
      // Navigate to HomePage and remove all previous routes
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const RootScreen()),
          (Route<dynamic> route) => false, // Change to false to remove all previous routes
        );
      }
    } on FirebaseAuthException catch (e) {
    Navigator.pop(context); // Close loading indicator

    setState(() {
      switch (e.code) {
        case 'invalid-credential':
          emailError = "Email or Password is wrong please try again";
          break;
        case 'wrong-password':
          passwordError = "Incorrect password. Please try again.";
          break;
        case 'invalid-email':
          emailError = "The email address is badly formatted.";
          break;
        case 'user-disabled':
          emailError = "This user account has been disabled.";
          break;
        case 'too-many-requests':
          emailError = "Too many unsuccessful login attempts. Please try again later.";
          break;
        default:
          emailError = "An error occurred. Please try again.";
          print("Firebase Auth Error: ${e.code}"); // For debugging
      }
    });
  } catch (e) {
    Navigator.pop(context); // Close loading indicator
    setState(() {
      emailError = "An unexpected error occurred. Please try again.";
      print("Unexpected Error: $e"); // For debugging
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 100),
                  Icon(Icons.lock, size: 100, color: Colors.red.shade700),
                  const SizedBox(height: 20),
                  Text(
                    'Welcome Back! Log in Here',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Email Input
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      fillColor: Colors.grey.shade300,
                      filled: true,
                      hintText: 'Email',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Password Input
                  TextFormField(
                    controller: passwordController,
                    obscureText: passToggle,
                    decoration: InputDecoration(
                      fillColor: Colors.grey.shade300,
                      filled: true,
                      hintText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          passToggle ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed:
                            () => setState(() => passToggle = !passToggle),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                        TextFormField(
                            enabled: false,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              errorText: emailError ?? passwordError,
                              errorStyle: TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                            ),
                          ),
                    const SizedBox(height: 5),

                  // Register & Forgot Password Links
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Not a member?',
                        style: TextStyle(color: Colors.grey[800]),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {

                        Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RegisterPage(),
                        ),
                      );

                        },
                        child: Text(
                          'Register!',
                          style: TextStyle(
                            color: Colors.red.shade500,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ForgotPasswordPage(),
                        ),
                      );
                    },
                    child: Text(
                      'Forgot your password?',
                      style: TextStyle(
                        color: Colors.red.shade500,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),

                  // Login Button
                  FloatingActionButton(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.grey[200],
                    onPressed: signUserIn,
                    child: const Icon(Icons.arrow_forward, size: 25),
                  ),
                  const SizedBox(height: 25),

                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(thickness: 1, color: Colors.grey[400]),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('Or Log in With'),
                        ),
                        Expanded(
                          child: Divider(thickness: 1, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Social Logins
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SquareTile(
                        imagePath: 'lib/assets/Images/google-logo.png',
                        onPressed: () => AuthService().signInWithGoogle(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
