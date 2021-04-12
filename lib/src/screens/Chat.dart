import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'Settings.dart';
import '../UserData.dart';
import '../globals.dart' as globals;

/// Tela de conversa.
///
/// Permite a troca de mensagens entre o usuário logado e outro cadastrado.
///
/// Estrutura de uma mensagem no Firestore:
///
/// **suid**: <String> ID único do usuário remetente, gerado pelo Firebase Auth
///
/// **ruid**: <String, null> ID único do usuário destinatário, gerado pelo Firebase Auth
///
/// **time**: <Timestamp> Horário de envio da mensagem
///
/// **type**: <String> Tipo de mensagem <'text', 'image'>
///
/// **contents**: <String> Conteúdo da mensagem <texto, url>
///
class ChatScreen extends StatefulWidget{
  ChatScreen(this.destinatary);
  final UserData destinatary;

  @override
  _ChatScreenState createState() => _ChatScreenState(destinatary);
}

class _ChatScreenState extends State<ChatScreen>{
  _ChatScreenState(this.destinatary);
  final UserData destinatary;

  final inputController = TextEditingController(text: '');
  final scrollController = ScrollController();
  bool uploadingFile = false;
  Stream<QuerySnapshot> stream;

  /// Envia uma mensagem contendo uma imagem.
  Future sendImage() async {
    var pickedFile = await ImagePicker().getImage(source: ImageSource.gallery);
    var image = File(pickedFile.path);
    if(image == null) return;

    setState(() { uploadingFile = true; });

    var auth = FirebaseAuth.instance;
    var db = FirebaseFirestore.instance;
    var st = FirebaseStorage.instance;
    var time = Timestamp.now();

    var path = st.ref()
        .child('messages')
        .child(auth.currentUser.uid)
        .child(destinatary.uid)
        .child(time.toString());

    path.putFile(image).snapshotEvents.listen((event) async {
      if (event.state == TaskState.success) {
        path.getDownloadURL().then((url) {
          var data = {
            'suid': auth.currentUser.uid,
            'ruid': destinatary.uid,
            'time': time,
            'type': 'image',
            'contents': url
          };

          db.collection('messages')
              .doc(auth.currentUser.uid)
              .collection(destinatary.uid)
              .add(data)
              .then((value) { setState(() { uploadingFile = false; }); });

          db.collection('messages')
              .doc(destinatary.uid)
              .collection(auth.currentUser.uid)
              .add(data);

          // Acessado pelo usuário atual
          db.collection('conversations')
              .doc(auth.currentUser.uid)
              .collection('last_message')
              .doc(destinatary.uid)
              .set({
            'uid': destinatary.uid,
            'time': time,
            'type': 'image',
            'contents': url
          });

          // Acessado pelo destinatário
          db.collection('users').doc(auth.currentUser.uid).get().then((user) {
            db.collection('conversations')
                .doc(destinatary.uid)
                .collection('last_message')
                .doc(auth.currentUser.uid)
                .set({
              'uid': auth.currentUser.uid,
              'time': time,
              'type': 'image',
              'contents': url
            });
          });


        });
      }
    });

    // Busca os dados do usuário atual
    db.collection('users').doc(auth.currentUser.uid).get().then((snapshot) {
      var user = UserData(snapshot.data());

      // Enviar push-notification
    if(destinatary.sid != null){
      OneSignal.shared.postNotification(OSCreateNotification(
          playerIds: [destinatary.sid],
          content: "imagem",
          heading: user.name,
          sendAfter: DateTime.now().add(Duration(milliseconds: 10))
      ));
    }});
  }

  /// Envia uma mensagem de texto.
  Future sendMessage() async {
    if (inputController.text.trim().isEmpty) return;
    var auth = FirebaseAuth.instance;
    var db = FirebaseFirestore.instance;
    var time = Timestamp.now();

    var content = inputController.text;
    setState(() { inputController.text = ''; });

    var data = {
      'suid': auth.currentUser.uid,
      'ruid': destinatary.uid,
      'time': time,
      'type': 'text',
      'contents': content
    };

    db.collection('messages')
        .doc(auth.currentUser.uid)
        .collection(destinatary.uid)
        .add(data);

    db.collection('messages')
        .doc(destinatary.uid)
        .collection(auth.currentUser.uid)
        .add(data);

    // Acessado pelo usuário atual
    db.collection('conversations')
        .doc(auth.currentUser.uid)
        .collection('last_message')
        .doc(destinatary.uid)
        .set({
      'uid': destinatary.uid,
      'time': time,
      'type': 'text',
      'contents': content
    });

    // Acessado pelo destinatário
    db.collection('users').doc(auth.currentUser.uid).get().then((user) {
      db.collection('conversations')
          .doc(destinatary.uid)
          .collection('last_message')
          .doc(auth.currentUser.uid)
          .set({
            'uid': auth.currentUser.uid,
            'time': time,
            'type': 'text',
            'contents': content
      });
    });

    // Busca os dados do usuário atual
    db.collection('users').doc(auth.currentUser.uid).get().then((snapshot) {
      var user = UserData(snapshot.data());

      // Enviar push-notification
      if(destinatary.sid != null){
        OneSignal.shared.postNotification(OSCreateNotification(
            playerIds: [destinatary.sid],
            content: content,
            heading: user.name,
            sendAfter: DateTime.now().add(Duration(milliseconds: 10))
        ));
      }
    });
  }

  @override
  void initState() {
    super.initState();

    var auth = FirebaseAuth.instance;
    var db = FirebaseFirestore.instance;

    stream = db.collection('messages')
        .doc(auth.currentUser.uid)
        .collection(destinatary.uid)
        .orderBy('time', descending: true)
        .snapshots();
  }

  @override
  void dispose() {
    super.dispose();
    scrollController.dispose();
    inputController.dispose();
  }

  @override
  Widget build(BuildContext context){
    var streamBuilder =
    StreamBuilder(
        stream: stream,
        builder: (context, snapshot) {
          var auth = FirebaseAuth.instance;

          switch(snapshot.connectionState){
            case ConnectionState.waiting:
              return Center(child: CircularProgressIndicator(backgroundColor: Color(0xFF3F9FFF)));
              break;
            case ConnectionState.active:
            case ConnectionState.done:
            var data = snapshot.data as QuerySnapshot;
            if(data.size == 0) return Container();
            return ListView.builder(
                reverse: true,
                controller: scrollController,
                itemCount: data.docs.length,
                itemBuilder: (context, index){
                  var message = data.docs[index].data();
                  var radius = Radius.circular(24.0);
                  var date = (message['time'] as Timestamp).toDate();
                  return Align(
                      alignment: message['suid'] == auth.currentUser.uid
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Column(
                          children: [
                            SizedBox(height: 8.0),
                            IntrinsicWidth(
                                child: IntrinsicHeight(
                                    child: Container(
                                        constraints: BoxConstraints( minHeight: 48, minWidth: 100, maxWidth: MediaQuery.of(context).size.width * 0.75),
                                        padding: EdgeInsets.all(12.0),
                                        decoration: message['suid'] == auth.currentUser.uid
                                            ? BoxDecoration(color: Color(0xFF3F9FFF), borderRadius: BorderRadius.only(topLeft: radius, bottomLeft: radius, topRight: radius))
                                            : BoxDecoration(color: Color(0xFF262D31), borderRadius: BorderRadius.only(bottomLeft: radius, bottomRight: radius, topRight: radius)),
                                        child:
                                        Row(
                                            children: [
                                              message['type'] == 'image'
                                                  ? Flexible(
                                                  child: ClipRRect(
                                                      borderRadius: BorderRadius.circular(12.0),
                                                      child: Image(
                                                          image: NetworkImage(message['contents']))))
                                                  : Flexible(
                                                child: Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: Text(
                                                        message['contents'],
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontStyle: FontStyle.normal,
                                                            fontWeight: FontWeight.w400,
                                                            fontSize: 16.0))),
                                              ),
                                              SizedBox(width: 8.0),
                                              Align(
                                                  alignment: Alignment.bottomRight,
                                                  child: Text(
                                                      '${date.hour}:${(date.minute < 10 ? '0' : '')}${date.minute}',
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontStyle: FontStyle.normal,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 12.0)))])))),
                            SizedBox(height: 8.0)]));});
              break;
            default:
              return Container();
              break;}});

    var inputBox =
    Container(
        alignment: Alignment.bottomCenter,
        padding: EdgeInsets.fromLTRB(8.0, 8.0, 0.0, 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
                child: Container(
                    constraints: BoxConstraints(minHeight: 48.0),
                    padding: EdgeInsets.only(left: 16.0),
                    decoration: BoxDecoration(
                        color: Color(0xFF3F9FFF),
                        borderRadius: BorderRadius.circular(24.0)),
                    child: Row(
                      //crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: TextField(
                              autofocus: false,
                              maxLines: null,
                              controller: inputController,
                              style: globals.chatInputTextStyle,
                              decoration: InputDecoration(
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  hintText: 'Digite uma mensagem',
                                  hintStyle: globals.chatInputHintTextStyle))),
                        uploadingFile
                            ? Padding(
                            padding: EdgeInsets.only(right: 16),
                            child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(backgroundColor: Colors.white)))
                            : IconButton(
                            padding: EdgeInsets.all(0.0),
                            icon: Icon(Icons.photo, size: 24.0, color: Colors.white),
                            onPressed: sendImage)]))),
            SizedBox(width: 8),
            Container(
                constraints: BoxConstraints(minHeight: 48.0, maxHeight: 48.0),
                child: ElevatedButton(
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Color(0xFF3F9FFF)),
                        shape: MaterialStateProperty.all(CircleBorder())),
                    onPressed: sendMessage,
                    child: Icon(Icons.send, size: 24.0, color: Colors.white)))]));

    return Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
            leadingWidth: 32,
            centerTitle: false,
            title: Container(
                padding: EdgeInsets.only(top: 8, bottom: 8),
                child: SingleChildScrollView(
                    child: Row(
                        children: [
                          CircleAvatar(
                              radius: 24,
                              backgroundImage: destinatary.url == null
                                  ? null
                                  : NetworkImage(destinatary.url)),
                          SizedBox(width: 8),
                          Text(
                              destinatary.name,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontStyle: FontStyle.normal,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20.0))]))),
            actions: [
              Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: IconButton(
                      icon: Icon(Icons.menu_rounded, size: 36.0),
                      onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen())); }))]),
        body: Container(
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: AssetImage('lib/assets/background.png'),
                    fit: BoxFit.cover)),
            child: SafeArea(
                child: Container(
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Expanded(child: streamBuilder),
                      inputBox])))));}}