import 'package:engineering_project/assets/components/auth_service.dart';
import 'package:engineering_project/assets/components/buttons.dart';
import 'package:engineering_project/assets/components/square_tile.dart';
import 'package:engineering_project/pages/Home_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool passToggle = true;

  void signUserIn() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
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
      showErrorDialog(e.message ?? "An error occurred. Please try again.");
    }
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Login Failed"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 110),
              Icon(Icons.lock, size: 100, color: Colors.red.shade700),
              const SizedBox(height: 20),
              Text(
                'Welcome Back! You can Log in Here',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 25),
              signup(
                controller: emailController,
                obscureText: false,
                hintText: 'Email',
                prefixIcon: Icon(Icons.email),
                suffix: null,
                validator: null,
              ),
              const SizedBox(height: 15),
              signup(
                controller: passwordController,
                obscureText: passToggle,
                hintText: 'Password',
                prefixIcon: Icon(Icons.lock),
                suffix: InkWell(
                  onTap: () {
                    setState(() {
                      passToggle = !passToggle;
                    });
                  },
                  child: Icon(
                    passToggle ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
                validator: null,
              ),
              const SizedBox(height: 9),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'You Are Not a Member?',
                    style: TextStyle(color: Colors.grey[800]),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Register!',
                    style: TextStyle(color: Colors.red.shade500),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Forgot your password?',
                    style: TextStyle(color: Colors.grey[800]),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              FloatingActionButton(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.grey[200],
                onPressed: signUserIn,
                child: Icon(Icons.arrow_forward, size: 25),
              ),
              const SizedBox(height: 25),
              Padding(
                padding: const EdgeInsets.fromLTRB(90, 0, 90, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(thickness: 1, color: Colors.grey[400]),
                    ),
                    Text('Or Log in With'),
                    Expanded(
                      child: Divider(thickness: 1, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
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
                    onPressed: null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
