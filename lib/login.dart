import 'package:engineering_project/assets/components/buttons.dart';
import 'package:engineering_project/assets/components/square_tile.dart';
import 'package:flutter/material.dart';

class login extends StatelessWidget {
  login({super.key});

  //Text Editing Controllers
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        // safearea make avoid the devices notch part on the screen
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 110),
              // logo
              Icon(Icons.lock, size: 100, color: Colors.red.shade700),

              const SizedBox(height: 20),

              // welcome text
              Text(
                'Hoşgeldin Buradan Giriş Yapabilirsin!',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 25),

              // username field
              signup(
                controller: usernameController,
                obscureText: false,
                hintText: 'Kullanici Adi',
              ),
              const SizedBox(height: 15),
              // password field
              signup(
                controller: passwordController,
                obscureText: true,
                hintText: 'Şifre',
              ),

              const SizedBox(height: 9),

              // forget password field
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Üye değil misin?',
                    style: TextStyle(color: Colors.grey[800]),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Kayıt Ol!',
                    style: TextStyle(color: Colors.blue),
                    ),
                ],
              ),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Şifremi Unuttum?',
                    style: TextStyle(color: Colors.grey[800]),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // sign in button
              FloatingActionButton(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.grey[200],
                onPressed: () {
                  // handle login
                  print('Login Button Pressed');
                },
                child: Icon(
                  Icons.arrow_forward,
                  size: 25,
                  ),
                ),

                const SizedBox(height: 25),

              //or continue with
              Padding(
                padding: const EdgeInsets.fromLTRB(90,0,90,0),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                      thickness: 1,
                      color: Colors.grey[400],
                    )
                  ),
                Text('Yada bunlar ile giriş yap'),
                            Expanded(
                child: Divider(
                  thickness: 1,
                  color: Colors.grey[400],
                )
                            ),
                          ],
                        ),
              ),
              
            const SizedBox(height: 25),
              // google + apple buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
              //google button
                  SquareTile(imagePath: 'lib/assets/Images/google-logo.png'),
              
              
              const SizedBox(width: 20),
              
                  SquareTile(imagePath: 'lib/assets/Images/apple-logo.png'),
              
                ],
              ),
                  
              // not a member ? register
                
            ],
          ),
        ),
      ),
    );
  }
}
