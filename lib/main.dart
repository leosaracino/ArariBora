import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'src/screens/SignIn.dart';

// TODO: Trocar o SHA-1 DEBUG para RELEASE https://developers.google.com/maps/documentation/android-sdk/get-api-key

/// Ponto de entrada do programa.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // TODO:veja: Auth Persistence
  if(FirebaseAuth.instance.currentUser != null){ await FirebaseAuth.instance.signOut(); }
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { FocusScope.of(context).requestFocus(FocusNode()); },
      child: MaterialApp(
          theme: ThemeData(
              primaryColor: Color(0xFF3F9FFF),
              accentColor: Color(0xFFFF3F3F),
              scaffoldBackgroundColor: Color(0xFF1F1F1F),
              hintColor: Color(0xFF7F7F7F)
          ),
          title: 'Grupo 03 - Verde',
          home: SignInScreen()
      ),
    );
  }
}