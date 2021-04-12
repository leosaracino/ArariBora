import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../globals.dart' as globals;

/// Tela de recuperação de senha.
class RecoveryScreen extends StatefulWidget{
  @override
  _RecoveryScreenState createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen>{
  final emailController = TextEditingController(text: '');

  /// Envia um email de recuperação de senha para o endereço fornecido.
  void sendRecoveryEmail() {
    var task = FirebaseAuth.instance.sendPasswordResetEmail(email: emailController.text.trim());
    task
        .then((value) => { globals.ShowSnackbarMessage(context, 'E-mail de recuperação enviado.') })
        .onError((error, stackTrace) => {globals.ShowSnackbarMessage(context, 'Falha ao enviar e-mail de recuperação.')});
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
            centerTitle: false,
            leadingWidth: 32,
            title: Text('Recuperação de senha', style: globals.appBarTextStyle)),
        body: Center(
            child: SingleChildScrollView(
                child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                        children: [
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
                          SizedBox(height: 64),
                          ConstrainedBox(
                              constraints: BoxConstraints(minWidth: 800.0, minHeight: 56.0, maxHeight: 56.0),
                              child: ElevatedButton(
                                  style: ButtonStyle(
                                      backgroundColor: MaterialStateProperty.all(Color(0xFFFF3F3F)),
                                      shape: MaterialStateProperty.all(RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(28.0)))),
                                  onPressed: sendRecoveryEmail,
                                  child: Text(
                                      'ENVIAR E-MAIL DE RECUPERAÇÃO',
                                      style: globals.buttonTextStyle)))])))));}}