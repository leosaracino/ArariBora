import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'Settings.dart';
import 'Chat.dart';
import 'SelectContacts.dart';
import '../UserData.dart';
import '../globals.dart' as globals;

/// Tela de contatos.
///
/// Mostra todos os demais usuários cadastrados.
class ContactsScreen extends StatefulWidget{
  @override
  _ContactsScreenState createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen>{
  Future<List<dynamic>> getUsers() async {
    var auth = FirebaseAuth.instance;
    var db = FirebaseFirestore.instance;

    var snapshot = await db.collection('users').get();
    var users = [];
    for (var user in snapshot.docs){
      if (user.data()['uid'] == null || user.data()['uid'] == auth.currentUser.uid) continue;
      users.add(user.data());
    }
    return users;
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
            leadingWidth: 32,
            centerTitle: false,
            title: Text('Contatos', style: globals.appBarTextStyle),
            actions: [
              Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: IconButton(
                  icon: Icon(Icons.menu_rounded, size: 36.0),
                  onPressed: (){ Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen())); }))]),
        body: FutureBuilder(
            future: getUsers(),
            builder: (context, snapshot) {
              switch(snapshot.connectionState){
                case ConnectionState.active:
                case ConnectionState.done:
                  return ListView.builder(
                      itemCount: snapshot.data.length + 1,
                      itemBuilder: (context, index) {
                        if(index == 0){
                          return ListTile(
                              contentPadding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                              leading: CircleAvatar(
                                  radius: 24,
                                  child: Icon(Icons.add, size: 28)),
                              title: Text(
                                  "Criar grupo",
                                  style: globals.buttonTextStyle),
                              onTap: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).push(MaterialPageRoute(builder: (context) => SelectContactsScreen()));
                              });
                        }
                        else{
                          var user = UserData(snapshot.data[index - 1]);
                          return ListTile(
                              contentPadding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                              leading: CircleAvatar(
                                  radius: 24,
                                  backgroundImage: user.url == null
                                      ? null
                                      : NetworkImage(user.url)),
                              title: Text(
                                  user.name,
                                  style: globals.buttonTextStyle),
                              onTap: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChatScreen(user)));
                              });
                        }});
                  break;
                default:
                  return Center(child: CircularProgressIndicator(backgroundColor: Color(0xFF3F9FFF)));
                  break;}}));}}


