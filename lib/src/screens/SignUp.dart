import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'Home.dart';
import '../globals.dart' as globals;

/// Tela de cadastramento de usuário.
class SignUpScreen extends StatefulWidget{
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>{
  final nameController = TextEditingController(text: '');
  final emailController = TextEditingController(text: '');
  final passwordController = TextEditingController(text: '');

  /// Registra um usuário Firebase Auth e salva suas informações no Firestore
  Future signUp() async {
    var name = nameController.text.trim();
    var email = emailController.text.trim();
    var password = passwordController.text;

    if (name.isEmpty){
      globals.ShowSnackbarMessage(context, 'Nome inválido.');
      return;
    }

    try {
      var auth = FirebaseAuth.instance;
      var db = FirebaseFirestore.instance;

      // Create Auth user
      await auth.createUserWithEmailAndPassword(email: email, password: password);

      // Create OneSignal user
      var status = await OneSignal.shared.getPermissionSubscriptionState();

      var position = await Geolocator.getLastKnownPosition();
      // Save user in Firebase Firestore (see globals for user structure)
      await  db.collection('users').doc(auth.currentUser.uid).set({
        'uid': auth.currentUser.uid,
        'sid': status.subscriptionStatus.userId,
        'url': null,
        'lat': position.latitude,
        'lng': position.longitude,
        'name': name,
        'time': Timestamp.now(),
        'email': email
      })
      .then((value) {
        print('User added');
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => HomeScreen()));
        globals.ShowSnackbarMessage(context, 'Usuário cadastrado com sucesso.');
      })
      .catchError((error) {
        globals.ShowSnackbarMessage(context, 'Erro ao cadastrar usuário.');
      });
    }
    on FirebaseAuthException catch (e) {
      if (e.code == 'malformed-email'){
        globals.ShowSnackbarMessage(context, 'E-mail inválido.');
      }
      else if (e.code == 'email-already-in-use') {
        globals.ShowSnackbarMessage(context, 'E-mail já cadastrado.');
      }
      else if (e.code == 'weak-password') {
        globals.ShowSnackbarMessage(context, 'Senha deve conter ao menos 6 caracteres.');
      }
    } catch (e) {
      print(e);
      return;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
          centerTitle: false,
          leadingWidth: 32,
          title: Text('ArariBora', style: globals.appBarTextStyle)),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ConstrainedBox(
                    constraints: BoxConstraints(minWidth: 100.0, minHeight: 32.0, maxHeight: 32.0),
                    child: TextField(
                        controller: nameController,
                        style: globals.inputTextStyle,
                        decoration: InputDecoration(
                            hintStyle: globals.inputHintTextStyle,
                            hintText: 'nome',
                            enabledBorder: globals.defaultInputBorder,
                            focusedBorder: globals.defaultFocusedInputBorder))),
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
                SizedBox(height: 64),
                ConstrainedBox(
                    constraints: BoxConstraints(minWidth: 800.0, minHeight: 56.0, maxHeight: 56.0),
                    child: ElevatedButton(
                      style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(Color(0xFFFF3F3F)),
                          shape: MaterialStateProperty.all(RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28.0)))),
                      onPressed: signUp,
                      child: Text(
                        'ENVIAR',
                        style: globals.buttonTextStyle)))])))));}}