import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:g03verdeuff/src/GroupData.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../UserData.dart';
import '../GroupData.dart';
import '../globals.dart' as globals;

/// Tela de configuração do aplicativo.
class CreateGroupScreen extends StatefulWidget {
  CreateGroupScreen(this.users);
  var users;
  @override
  _CreateGroupScreenState createState() => _CreateGroupScreenState(users);
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  _CreateGroupScreenState(users);
  var users;
  var url;
  UserData currentUser;
  //GroupData group = GroupData();
  final picker = ImagePicker();
  final nameController = TextEditingController(text: '');



  /// Operação assíncrona que busca os dados do usuário no Firebase antes de construir este widget.
  Future initializer;



  /// Atualiza a imagem de peril do usuário na Cloud Storage e no Firebase.
  Future setImage(String source) async {
    var db = FirebaseFirestore.instance;
    var st = FirebaseStorage.instance;

    if(source == 'remove'){
      url = null;
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


  /// Encerra a sessão de autenticação do Firebase Auth e retorna o aplicativo à tela de login.
  Future createGroup() async {
    var db = FirebaseFirestore.instance;

    var name = nameController.text.trim();
    users.add(currentUser.uid);

    if (name.isEmpty){
      globals.ShowSnackbarMessage(context, 'Nome inválido.');
      return;
    }

    await db.collection("groups").add({
      "name" : name,
      "url"  : url,
      "users": FieldValue.arrayUnion(users),
    });

    print("foi");
    Navigator.pushNamedAndRemoveUntil(
        context, "/home", (_)=>false
    );

  }

  @override
  void initState() {
    super.initState();

    var auth = FirebaseAuth.instance;
    var db = FirebaseFirestore.instance;

    initializer = db.collection('users').doc(auth.currentUser.uid).get().then((value) {
      currentUser = UserData(value.data());
    });
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
                                    width: 120.0,
                                    height: 120.0,
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
                                        child: Text('Criar grupo',
                                            style: globals.buttonTextStyle)))])));})));}}