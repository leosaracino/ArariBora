import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'SignIn.dart';
import '../UserData.dart';
import '../globals.dart' as globals;

/// Tela de configuração do aplicativo.
class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserData currentUser;
  final picker = ImagePicker();
  final nameController = TextEditingController(text: '');
  final emailController = TextEditingController(text: '');

  /// Operação assíncrona que busca os dados do usuário no Firebase antes de construir este widget.
  Future initializer;

  /// Atualiza a imagem de peril do usuário na Cloud Storage e no Firebase.
  Future setImage(String source) async {
    var db = FirebaseFirestore.instance;
    var st = FirebaseStorage.instance;

    if(source == 'remove'){
      setState(() { currentUser.url = null; });
      await db.collection('users')
          .doc(currentUser.uid)
          .update({'url': null});

      st.ref().child('profile').child(currentUser.uid + '.jpg').delete();
    }
    else
    {
      PickedFile pickedFile;
      if(source == 'gallery'){
        pickedFile = await picker.getImage(source: ImageSource.gallery); }
      if(source == 'camera'){        // Often crashes the app, known bug
        pickedFile = await picker.getImage(source: ImageSource.camera); }

      var image = File(pickedFile.path);
      if(image == null) return;

      await db
          .collection('users')
          .doc(currentUser.uid)
          .update({'url': null});

      // Upload image to Cloud Storage
      var path = st.ref().child('profile').child(currentUser.uid + '.jpg');
      var task = path.putFile(image);
      task.snapshotEvents.listen((event) async {
        if(event.state == TaskState.success){
          // Get download link to file
          var url = await path.getDownloadURL();

          // Upload reference to URL to Firestore
          await db
              .collection('users')
              .doc(currentUser.uid)
              .update({'url': url});

          // Refresh Widget
          setState(() { currentUser.url = url; });
        }
      });
    }
  }

  /// Atualiza o nome do usuário no Firebase.
  Future setName() async {
    var name = nameController.text.trim();
    var auth = FirebaseAuth.instance;
    var db = FirebaseFirestore.instance;

    if (name.isNotEmpty) {
      await db.collection('users')
          .doc(auth.currentUser.uid)
          .update({'name': name});

      var data = await db.collection('users').doc(currentUser.uid).get();
      setState(() {
        currentUser.name = data.data()['name'];
        nameController.text = data.data()['name'];
      });

      globals.ShowSnackbarMessage(context, 'Nome atualizado com sucesso.');
    }
  }

  /// Atualiza o email de cadastro do usuário no Firebase Auth e Firestore.
  Future setEmail() async {
    var auth = FirebaseAuth.instance;
    var db = FirebaseFirestore.instance;
    var authUser = auth.currentUser;

    var email = emailController.text.trim();
    if (email.isNotEmpty) {
      try {
        await authUser.updateEmail(email);
        await db.collection('users')
            .doc(currentUser.uid)
            .update({'email': authUser.email});

        globals.ShowSnackbarMessage(context, 'E-mail alterado com sucesso.');
      } on FirebaseAuthException catch (e) {
        if (e.code == 'invalid-email') {
          globals.ShowSnackbarMessage(context, 'E-mail inválido.');
        } else if (e.code ==
            'email-already-in-use') {
          globals.ShowSnackbarMessage(context, 'E-mail em uso.');
        }
      } catch (e) {
        print(e);
      }

      setState(() { emailController.text = authUser.email; });
    }
  }

  /// Encerra a sessão de autenticação do Firebase Auth e retorna o aplicativo à tela de login.
  Future signOut() async {
    await FirebaseAuth.instance.signOut();
    await Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => SignInScreen()), (Route<dynamic> route) => false);
  }

  @override
  void initState() {
    super.initState();

    var auth = FirebaseAuth.instance;
    var db = FirebaseFirestore.instance;

    initializer = db.collection('users').doc(auth.currentUser.uid).get().then((value) {
      currentUser = UserData(value.data());
      nameController.text = currentUser.name;
      emailController.text = currentUser.email;
    });
  }
  @override
  void dispose() {
    super.dispose();
    nameController.dispose();
    emailController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
            leadingWidth: 32,
            centerTitle: false,
            title: Text('Configurações', style: globals.appBarTextStyle)),
        body: Center(
            child: FutureBuilder(
                future: initializer,
                builder: (context, snapshot){
                  return snapshot.connectionState != ConnectionState.done
                      ? CircularProgressIndicator(backgroundColor: Color(0xFF3F9FFF))
                      : SingleChildScrollView(
                      child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Column(
                              children: [
                                Container(
                                    width: 192.0,
                                    height: 192.0,
                                    child: Stack(children: [
                                      CircleAvatar(
                                          radius: 96,
                                          backgroundImage: currentUser.url == null
                                              ? null
                                              : NetworkImage(currentUser.url)),
                                      Align(
                                          alignment: Alignment.bottomRight,
                                          child: PopupMenuButton<String>(
                                              onSelected: (String source) => { setImage(source) },
                                              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                                PopupMenuItem<String>(
                                                    value: 'remove',
                                                    child: Row(children: [
                                                      Icon(Icons.delete, size: 24.0, color: Colors.black),
                                                      SizedBox(width: 8),
                                                      Text('Remover', style: TextStyle(color: Colors.black, fontSize: 16.0))])),
                                                PopupMenuItem<String>(
                                                    value: 'camera',
                                                    child: Row(children: [
                                                      Icon(Icons.camera_alt, size: 24.0, color: Colors.black),
                                                      SizedBox(width: 8),
                                                      Text('Câmera', style: TextStyle(color: Colors.black, fontSize: 16.0))])),
                                                PopupMenuItem<String>(
                                                    value: 'gallery',
                                                    child: Row(children: [
                                                      Icon(Icons.photo, size: 24.0, color: Colors.black),
                                                      SizedBox(width: 8),
                                                      Text('Galeria', style: TextStyle(color: Colors.black, fontSize: 16.0))]))],
                                              child: Container(
                                                  width: 56.0,
                                                  height: 56.0,
                                                  decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: Color(0xFF3F9FFF)),
                                                  child: Icon(Icons.edit, size: 24.0, color: Colors.white))))])),
                                SizedBox(height: 32),
                                Row(children: [
                                  SizedBox(width: 32),
                                  Flexible(
                                      child: ConstrainedBox(
                                          constraints: BoxConstraints(minWidth: 100.0, minHeight: 32.0, maxHeight: 32.0),
                                          child: TextField(
                                              controller: nameController,
                                              style: globals.inputTextStyle,
                                              decoration: InputDecoration(
                                                  enabledBorder: globals.defaultInputBorder,
                                                  focusedBorder: globals.defaultFocusedInputBorder),
                                              onSubmitted: (String value) { setName(); }))),
                                  SizedBox(width: 8),
                                  Icon(Icons.edit, size: 24.0, color: Colors.white)]),
                                SizedBox(height: 32),
                                Row(
                                    children: [
                                      SizedBox(width: 32),
                                      Flexible(
                                          child: ConstrainedBox(
                                              constraints: BoxConstraints(minWidth: 100.0, minHeight: 32.0, maxHeight: 32.0),
                                              child: TextField(
                                                  controller: emailController,
                                                  style: globals.inputTextStyle,
                                                  decoration: InputDecoration(
                                                      enabledBorder: globals.defaultInputBorder,
                                                      focusedBorder: globals.defaultFocusedInputBorder),
                                                  onSubmitted: (String value) { setEmail(); }))),
                                      SizedBox(width: 8),
                                      Icon(Icons.edit, size: 24.0, color: Colors.white)]),
                                SizedBox(height: 32),
                                ConstrainedBox(
                                    constraints: BoxConstraints(
                                        minWidth: 800.0, minHeight: 56.0, maxHeight: 56.0),
                                    child: ElevatedButton(
                                        style: ButtonStyle(
                                            backgroundColor:
                                            MaterialStateProperty.all(Color(0xFFFF3F3F)),
                                            shape: MaterialStateProperty.all(
                                                RoundedRectangleBorder(
                                                    borderRadius:
                                                    BorderRadius.circular(28.0)))),
                                        onPressed: signOut,
                                        child: Text('DESCONECTAR-SE',
                                            style: globals.buttonTextStyle)))])));})));}}