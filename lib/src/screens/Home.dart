import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/rendering.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Settings.dart';
import 'Conversations.dart';
import 'Chat.dart';
import '../UserData.dart';
import '../globals.dart' as globals;

/// Tela principal do aplicativo, conténdo o mapa e acesso às demais telas.
class HomeScreen extends StatefulWidget{
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>{
  final storedUsers = <String, UserData>{};
  final markers = <String, Marker>{};
  Timer timer;

  /// Atualiza os campos de latitude e longitude do usuário no Firestore
  Future updateUserLatLng () async {
    var auth = FirebaseAuth.instance;
    var db = FirebaseFirestore.instance;

    var position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    if(position == null){
      print('Home: updateUserLatLng: Position == null!');
      return;
    }

    // Current user data currently stored in Firestore
    var task = await db.collection('users').doc(auth.currentUser.uid).get();
    var data = UserData(task.data());

    var distance = Geolocator.distanceBetween(data.lat, data.lng, position.latitude, position.longitude);
    if(distance <= 5) {
      print('Home: updateUserLatLng: Distance < 5m!');
      return;
    }

    db.collection('users').doc(auth.currentUser.uid).update({
      'lat': position.latitude,
      'lng': position.longitude
    });

    print('Home: updateUserLatLng: (${position.latitude}, ${position.longitude})');
  }

  /// Cria uma instância da classe Marker com os dados do usuário fornecido
  Marker createMarker(UserData user){
    return Marker(
      point: LatLng(user.lat, user.lng),
      width: 48,
      height: 48,
      builder: (BuildContext context){
        return ElevatedButton(
            style: ButtonStyle(
                padding: MaterialStateProperty.all(EdgeInsets.all(4)),
                backgroundColor: MaterialStateProperty.all(Color(0xFF3F9FFF)),
                shape: MaterialStateProperty.all(CircleBorder())
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(user)));
            },
            child: user.url != null
              ? CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(user.url))
              : Text(user.name[0], style: globals.buttonTextStyle));});
  }

  @override
  void initState() {
    super.initState();
    var auth = FirebaseAuth.instance;
    var db = FirebaseFirestore.instance;

    var stream = db.collection('users')
        .where('uid', isNotEqualTo: auth.currentUser.uid)
        .snapshots()
        .asBroadcastStream();

    stream.listen((event) {
      event.docChanges.forEach((change) {
        var user = UserData(change.doc.data());
        switch(change.type){
          case DocumentChangeType.added:
          case DocumentChangeType.modified:
            setState(() {
              storedUsers[user.uid] = user;
              markers[user.uid] = createMarker(user);
            });
            break;
          default:
            break;
        }
      });
    });

    // Tries to update the user's LatLng in Firestore every 3 seconds
    timer = Timer.periodic(Duration(seconds: 3), (Timer t) { updateUserLatLng(); });
  }

  @override
  void dispose(){
    super.dispose();
    timer.cancel();
  }

  @override
  Widget build(BuildContext context){
    var map =
    FlutterMap(
      options: MapOptions(
        center: LatLng(-22.90614915134549, -43.13322913488855),
        zoom: 16.0),
      layers: [
        TileLayerOptions(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c']),
        MarkerLayerOptions(
            markers: markers.values.toList())]);

    var conversationsButton =
    Align(
      alignment: Alignment.bottomCenter,
      child: Container(
          constraints: BoxConstraints(minWidth: 800.0, minHeight: 88.0, maxHeight: 88.0),
          padding: EdgeInsets.fromLTRB(32, 16, 32, 16),
          child: ElevatedButton(
              style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Color(0xFF3F9FFF)),
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28.0)))),
              onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (context) => ConversationsScreen())); },
              child: Icon(Icons.message_outlined, size: 32.0))));

    return WillPopScope(
      onWillPop: () async { return false; },
      child: Scaffold(
          appBar: AppBar(
              leadingWidth: 0,
              centerTitle: false,
              leading: Container(),
              title: Text('Grupo 03 - Verde', style: globals.appBarTextStyle),
              actions: [
                Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: IconButton(
                    icon: Icon(Icons.menu_rounded, size: 36.0),
                    onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen())); }))]),
          body: Stack(
              children:[
                map,
                conversationsButton])));}}
