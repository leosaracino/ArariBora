import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'Settings.dart';
import 'Contacts.dart';
import 'Chat.dart';
import '../UserData.dart';
import '../globals.dart' as globals;

/// Tela de conversas.
///
/// Mostra os usuários com quem o usuário atual já trocou mensagens e a mensagem mais recentre entre eles.
class ConversationsScreen extends StatefulWidget{
  @override
  _ConversationsScreenState createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen>{
  final scrollController = ScrollController();
  Stream stream;

  @override
  void initState() {
    super.initState();

    var auth = FirebaseAuth.instance;
    var db = FirebaseFirestore.instance;

    stream = db.collection('conversations')
               .doc(auth.currentUser.uid)
               .collection('last_message')
               .snapshots();
  }

  @override
  void dispose() {
    super.dispose();
    scrollController.dispose();
  }

  @override
  Widget build(BuildContext context){
    var db = FirebaseFirestore.instance;

    var streamBuilder =
    StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, querySnapshot) {
          // STREAM BUILDER STRATEGY
          switch(querySnapshot.connectionState){
            case ConnectionState.waiting:
              return Center(child: CircularProgressIndicator(backgroundColor: Color(0xFF3F9FFF)));
              break;
            case ConnectionState.active:
            case ConnectionState.done:
              return ListView.builder(
                  controller: scrollController,
                  itemCount: (querySnapshot.data).docs.length,
                  itemBuilder: (context, index) {
                    var message = (querySnapshot.data).docs[index].data();
                    print(message['uid']);
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: FutureBuilder<DocumentSnapshot>(
                          future: db.collection('users').doc(message['uid']).get(),
                          builder: (context, documentSnapshot) {
                            // FUTURE BUILDER STRATEGY
                            switch(documentSnapshot.connectionState){
                              case ConnectionState.waiting:
                                return Container(
                                    height: 64,
                                    alignment: Alignment.centerLeft,
                                    padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                                    child: CircularProgressIndicator(backgroundColor: Color(0xFF3F9FFF)));
                                break;
                              case ConnectionState.active:
                              case ConnectionState.done:
                                var user = UserData(documentSnapshot.data.data());
                                return ListTile(
                                    contentPadding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                                    leading: CircleAvatar(
                                        radius: 24,
                                        backgroundImage: user.url == null
                                            ? null
                                            : NetworkImage(user.url)),
                                    title: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              user.name,
                                              style: globals.buttonTextStyle),
                                          message['type'] == 'text'
                                            ? Text(
                                              message['contents'],
                                              style: globals.inputHintTextStyle)
                                            : Row(
                                              children: [
                                                Icon(Icons.photo, color: Colors.white, size: 16.0),
                                                SizedBox(width: 8.0),
                                                Text(
                                                    'Imagem',
                                                    style: globals.inputHintTextStyle)])]),
                                    onTap: () { Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChatScreen(user))); });
                              default:
                                return Container();}}),);});
              break;
            default:
              return Container();
              break;}});

    var contactsButton =
    Container(
      alignment: Alignment.centerRight,
      padding: EdgeInsets.all(16.0),
      child: ElevatedButton(
          style: ButtonStyle(
              padding: MaterialStateProperty.all(EdgeInsets.zero),
              //fixedSize: MaterialStateProperty.all(Size.fromRadius(28.0)),
              backgroundColor: MaterialStateProperty.all(Color(0xFF3F9FFF)),
              shape: MaterialStateProperty.all(CircleBorder())),
          onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (context) => ContactsScreen())); },
          child: Icon(Icons.person, size: 36.0)));

    return Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
            centerTitle: false,
            leadingWidth: 32,
            title: Text('Conversas', style: globals.appBarTextStyle),
            actions: [
              Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: IconButton(
                      icon: Icon(Icons.menu_rounded, size: 36.0),
                      onPressed: (){ Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen())); }))]),
        body: SafeArea(
          child: Column(
              children: [
                Expanded(child: streamBuilder),
                contactsButton])));}}


