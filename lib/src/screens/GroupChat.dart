import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../GroupData.dart';
import 'Settings.dart';
import '../UserData.dart';
import '../globals.dart' as globals;

/// Tela de conversa.
///
/// Permite a troca de mensagens entre um grupo de usuários.
///
/// Estrutura de uma mensagem no Firestore:
///
/// **suid**: <String> ID único do usuário remetente, gerado pelo Firebase Auth
///
/// **ruid**: <String, null> ID único do grupo, gerado pelo Firebase Auth
///
/// **time**: <Timestamp> Horário de envio da mensagem
///
/// **type**: <String> Tipo de mensagem <'text', 'image'>
///
/// **contents**: <String> Conteúdo da mensagem <texto, url>
///
class GroupChatScreen extends StatefulWidget{
  GroupChatScreen(this.group);
  final GroupData group;

  @override
  _GroupChatScreenState createState() => _GroupChatScreenState(group);
}

class _GroupChatScreenState extends State<GroupChatScreen>{
  _GroupChatScreenState(this.group);
  GroupData group;
  List<UserData> users;
  UserData currentUser;

  final inputController = TextEditingController(text: '');
  final scrollController = ScrollController();
  bool uploadingFile = false;
  Stream<QuerySnapshot> stream;
  Future<List<UserData>> future;


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
        .child(currentUser.uid)
        .child(group.uid)
        .child(time.toString());

    path.putFile(image).snapshotEvents.listen((event) async {
      if (event.state == TaskState.success) {
        path.getDownloadURL().then((url) {
          List<String> sids = [];
          var data = {
            'suid': currentUser.uid,
            'ruid': group.uid,
            'time': time,
            'type': 'image',
            'contents': url
          };

          // Save message in group
          db.collection('groups')
            .doc(group.uid)
            .collection('messages')
            .add(data)
            .then((value) { setState(() { uploadingFile = false; }); });

          // Update users' last_message
          users.forEach((user) {
            db.collection('conversations')
                .doc(user.uid)
                .collection('last_message')
                .doc(group.uid)
                .set({
              'uid': group.uid,
              'time': time,
              'type': 'image',
              'contents': url
            });

            // Collect SID for push-notification
            if(user.uid != currentUser.uid && user.sid != null) { sids.add(user.sid); }
          });

          OneSignal.shared.postNotification(OSCreateNotification(
              playerIds: sids,
              content: 'imagem',
              heading: group.name,
              sendAfter: DateTime.now().add(Duration(milliseconds: 10))
          ));
        });
      }
    });
  }

  /// Envia uma mensagem de texto.
  Future sendMessage() async {
    if (inputController.text.trim().isEmpty) return;
    var auth = FirebaseAuth.instance;
    var db = FirebaseFirestore.instance;
    var time = Timestamp.now();

    var content = currentUser.name + ':\n' + inputController.text;
    setState(() { inputController.text = ''; });

    List<String> sids = [];
    var data = {
      'suid': currentUser.uid,
      'ruid': group.uid,
      'time': time,
      'type': 'text',
      'contents': content
    };

    // Save message in group
    db.collection('groups')
        .doc(group.uid)
        .collection('messages')
        .add(data);

    // Update users' last_message
    users.forEach((user) {
      db.collection('conversations')
          .doc(user.uid)
          .collection('last_message')
          .doc(group.uid)
          .set({
        'uid': group.uid,
        'time': time,
        'type': 'text',
        'contents': content
      });

      // Collect SID for push-notification
      if(user.uid != currentUser.uid && user.sid != null) { sids.add(user.sid); }
    });

    print(sids.toString());
    if(sids.length == 0) return;
    OneSignal.shared.postNotification(OSCreateNotification(
        playerIds: sids,
        content: content,
        heading: group.name,
        sendAfter: DateTime.now().add(Duration(milliseconds: 10))
    ));
  }

  @override
  void initState() {
    super.initState();

    var auth = FirebaseAuth.instance;
    var db = FirebaseFirestore.instance;

    stream = db.collection('groups')
        .doc(group.uid)
        .collection('messages')
        .orderBy('time', descending: true)
        .snapshots();

    future = new Future<List<UserData>>(() {
      List<UserData> data = [];
      group.users.forEach((userUID) {
        db.collection('users').doc(userUID).get().then((doc) {
          data.add(UserData(doc.data()));
          if(userUID == auth.currentUser.uid)
            currentUser = UserData(doc.data());
        });
      });
      users = data;
      return data;
    });
  }

  @override
  void dispose() {
    super.dispose();
    scrollController.dispose();
    inputController.dispose();
  }

  @override
  Widget build(BuildContext context){
    var auth = FirebaseAuth.instance;
    var db = FirebaseFirestore.instance;

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

    return FutureBuilder(
      future: future,
      builder: (context, snapshot){
        if(snapshot.connectionState == ConnectionState.active || snapshot.connectionState == ConnectionState.done){
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
                                    backgroundImage: group.url == null
                                        ? null
                                        : NetworkImage(group.url)),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                      group.name,
                                      overflow: TextOverflow.fade,
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontStyle: FontStyle.normal,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20.0)),
                                )]))),
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
                                inputBox])))));
        }
        else{
          return Center(child: CircularProgressIndicator(backgroundColor: Color(0xFF3F9FFF)));
        }
      }
    );}}