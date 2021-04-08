import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../UserData.dart';
import '../globals.dart' as globals;
import 'Home.dart';

/// Tela de criaçao de grupos.
class CreateGroupScreen extends StatefulWidget {
  CreateGroupScreen(this.users);
  final List<dynamic> users;
  @override
  _CreateGroupScreenState createState() => _CreateGroupScreenState(users);
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  _CreateGroupScreenState(this.users);
  List<dynamic> users;
  File imageFile;
  UserData currentUser;
  //GroupData group = GroupData();
  final picker = ImagePicker();
  final nameController = TextEditingController(text: '');

  /// Operação assíncrona que busca os dados do usuário no Firebase antes de construir este widget.
  Future initializer;

  /// Atualiza a imagem de perfil do grupo na Cloud Storage e no Firebase.
  Future setImage(String source) async {
    if(source == 'remove'){
      if(imageFile != null){
        imageFile.delete();
        setState(() { imageFile = null; });
      }
    }
    else
    {
      PickedFile pickedFile;
      if(source == 'gallery'){
        pickedFile = await picker.getImage(source: ImageSource.gallery); }
      if(source == 'camera'){        // Often crashes the app, known bug
        pickedFile = await picker.getImage(source: ImageSource.camera); }

      var image = File(pickedFile.path);
      if(image != null) setState(() { imageFile = image; });
    }
  }

  /// Salva o grupo no Firebase Firestore e sua imagem na Cloud Storage
  Future createGroup() async {
    var name = nameController.text.trim();
    if (name.isEmpty){
      globals.ShowSnackbarMessage(context, 'Nome inválido.');
      return;
    }

    var auth = FirebaseAuth.instance;
    var db = FirebaseFirestore.instance;
    var st = FirebaseStorage.instance;

    users.add(auth.currentUser.uid);

    // Begin storing group data in Firebase Firestore and get access to it's ID
    await db.collection("groups").add({
      "name" : name,
      "users": FieldValue.arrayUnion(users),
    }).then((doc) async {
      // Store image in Cloud Storage
      var path = st.ref().child('profile').child('groups').child(doc.id + '.jpg');
      await path.putFile(imageFile);
      var url = await path.getDownloadURL();

      // Finish storing group data in Firebase Firestore
      await db.collection('groups').doc(doc.id).update({'uid': doc.id, 'url': url});
    });

    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => HomeScreen()), (Route<dynamic> route) => false);
    globals.ShowSnackbarMessage(context, 'Grupo criado com sucesso!');
  }

  @override
  void dispose() {
    super.dispose();
    nameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
            leadingWidth: 32,
            centerTitle: false,
            title: Text('Criar grupo', style: globals.appBarTextStyle)),
        body: Center(
            child: SingleChildScrollView(
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
                                    backgroundImage: imageFile == null
                                        ? null
                                        : FileImage(imageFile)),
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
                                          hintStyle: globals.inputHintTextStyle,
                                          hintText: 'nome do grupo',
                                          enabledBorder: globals.defaultInputBorder,
                                          focusedBorder: globals.defaultFocusedInputBorder),
                                      //onSubmitted: (String value) { setName();}
                                    ))),
                            SizedBox(width: 8),
                            Icon(Icons.edit, size: 24.0, color: Colors.white)]),
                          SizedBox(height: 32),
                          ConstrainedBox(
                              constraints: BoxConstraints(
                                  minWidth: 800.0, minHeight: 56.0, maxHeight: 56.0),
                              child: ElevatedButton(
                                  style: ButtonStyle(
                                      backgroundColor:
                                      MaterialStateProperty.all(globals.colors['blue']),
                                      shape: MaterialStateProperty.all(
                                          RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(28.0)))),
                                  onPressed: createGroup,
                                  child: Text('CRIAR',
                                      style: globals.buttonTextStyle)))])))));}}