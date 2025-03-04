import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:engineering_project/assets/components/auth_service.dart';
import 'package:engineering_project/assets/components/square_tile.dart';
import 'package:engineering_project/pages/Home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

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
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      setState(() {
        if (e.code == 'user-not-found') {
          emailError = "No user found with this email.";
        } else if (e.code == 'wrong-password') {
          passwordError = "Incorrect password. Try again.";
        } else {
          emailError = e.message; // Show other Firebase errors
        }
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
                      hintText: 'Email',
                      prefixIcon: const Icon(Icons.email),
                      errorText: emailError,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: emailError != null ? Colors.red : Colors.grey),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        setState(() => emailError = "Enter your email");
                        return "";
                      } else if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(value)) {
                        setState(() => emailError = "Enter a valid email address");
                        return "";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),

                  // Password Input
                  TextFormField(
                    controller: passwordController,
                    obscureText: passToggle,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(passToggle ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => passToggle = !passToggle),
                      ),
                      errorText: passwordError,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: passwordError != null ? Colors.red : Colors.grey),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        setState(() => passwordError = "Enter your password");
                        return "";
                      } else if (value.length < 6) {
                        setState(() => passwordError = "Password must be at least 6 characters");
                        return "";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),

                  // Register & Forgot Password Links
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Not a member?', style: TextStyle(color: Colors.grey[800])),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          // Navigate to Register Page
                        },
                        child: Text('Register!', style: TextStyle(color: Colors.red.shade500, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  GestureDetector(
                    onTap: () {
                      // Navigate to Forgot Password Page
                    },
                    child: Text('Forgot your password?', style: TextStyle(color: Colors.grey[800])),
                  ),
                  const SizedBox(height: 25),

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
                        Expanded(child: Divider(thickness: 1, color: Colors.grey[400])),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('Or Log in With'),
                        ),
                        Expanded(child: Divider(thickness: 1, color: Colors.grey[400])),
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
                      const SizedBox(width: 20),
                      SquareTile(
                        imagePath: 'lib/assets/Images/apple-logo.png',
                        onPressed: () {
                          // Implement Apple Sign-In if needed
                        },
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