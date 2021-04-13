import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'Recovery.dart';
import 'SignUp.dart';
import 'Home.dart';
import '../globals.dart' as globals;

/// Tela de login.
class SignInScreen extends StatefulWidget{
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>{
  final emailController = TextEditingController(text: '');
  final passwordController = TextEditingController(text: '');

  /// Inicializa uma sessão de autenticação do Firebase Auth
  void signIn() async {
    var auth = FirebaseAuth.instance;
    var db = FirebaseFirestore.instance;

    try {
      await auth.signInWithEmailAndPassword(email: emailController.text.trim(), password: passwordController.text);
      if(auth.currentUser != null){
        // overwrite OneSignal user
        var status = await OneSignal.shared.getPermissionSubscriptionState();
        db.collection('users').doc(auth.currentUser.uid).update({'sid': status.subscriptionStatus.userId});
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => HomeScreen()));
      }
    }
    on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        globals.ShowSnackbarMessage(context, 'Usuário não cadastrado.');
      }
      else if (e.code == 'wrong-password') {
        globals.ShowSnackbarMessage(context, 'Senha incorreta.');
      }
    }
  }

  /// Checa se existe uma sessão de autenticação persistida.
  void checkForPersistance() async {
    var auth = FirebaseAuth.instance;
    var db = FirebaseFirestore.instance;

    if (auth.currentUser != null) {
      // overwrite OneSignal user
      var status = await OneSignal.shared.getPermissionSubscriptionState();
      db.collection('users').doc(auth.currentUser.uid).update({'sid': status.subscriptionStatus.userId});
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => HomeScreen()));
    }
  }

  @override
  void initState() {
    super.initState();
    checkForPersistance();
  }

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
  }

  @override
  Widget build(BuildContext context){
    return WillPopScope(
      onWillPop: () async { return false; },
      child: Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
              centerTitle: false,
              leadingWidth: 32),
          body: Center(
              child: SingleChildScrollView(
                  child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                          children:[
                            SizedBox(width: 160, height: 160, child: Image(image: AssetImage('lib/assets/logo.png'))),
                            SizedBox(height: 32),
                            ConstrainedBox(
                                constraints: BoxConstraints(minWidth: 100.0, minHeight: 32.0, maxHeight: 32.0),
                                child: TextField(
                                    controller: emailController,
                                    style: globals.inputTextStyle,
                                    decoration: InputDecoration(
                                        hintStyle: globals.inputHintTextStyle,
                                        hintText: 'e-mail',
                                        enabledBorder: globals.defaultInputBorder,
                                        focusedBorder: globals.defaultFocusedInputBorder))),
                            SizedBox(height: 32),
                            ConstrainedBox(
                                constraints: BoxConstraints(minWidth: 100.0, minHeight: 32.0, maxHeight: 32.0),
                                child: TextField(
                                    controller: passwordController,
                                    obscureText: true,
                                    style: globals.inputTextStyle,
                                    decoration: InputDecoration(
                                        hintStyle: globals.inputHintTextStyle,
                                        hintText: 'senha',
                                        enabledBorder: globals.defaultInputBorder,
                                        focusedBorder: globals.defaultFocusedInputBorder))),
                            Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                    onPressed: () { Navigator.of(context).push(MaterialPageRoute(builder: (context) => RecoveryScreen())); },
                                    child: Text(
                                        'Esqueci minha senha',
                                        style: globals.inputHintTextStyle))),
                            SizedBox(height: 16),
                            ConstrainedBox(
                                constraints: BoxConstraints(minWidth: 800.0, minHeight: 56.0, maxHeight: 56.0),
                                child: ElevatedButton(
                                    style: ButtonStyle(
                                        backgroundColor: MaterialStateProperty.all(Color(0xFFFF3F3F)),
                                        shape: MaterialStateProperty.all(RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(28.0)))),
                                    onPressed: signIn,
                                    child: Text(
                                        'ACESSAR',
                                        style: globals.buttonTextStyle))),
                            SizedBox(height: 32),
                            ConstrainedBox(
                                constraints: BoxConstraints(minWidth: 800.0, minHeight: 56.0, maxHeight: 56.0),
                                child: ElevatedButton(
                                    style: ButtonStyle(
                                        backgroundColor: MaterialStateProperty.all(Color(0xFF3F9FFF)),
                                        shape: MaterialStateProperty.all(RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(28.0)))),
                                    onPressed: () { Navigator.of(context).push(MaterialPageRoute(builder: (context) => SignUpScreen())); },
                                    child: Text(
                                        'CADASTRAR-SE',
                                        style: globals.buttonTextStyle)))]))))));}}
