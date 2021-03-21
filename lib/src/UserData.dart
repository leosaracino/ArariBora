import 'package:cloud_firestore/cloud_firestore.dart';

/// Define uma class UserData que facilita o acesso a dados de usuários.
///
/// Estrutura de um usuário no Firestore:
///
/// **uid**: <String> ID unico do usuário gerado pelo Firebase Auth
///
/// **url**: <String, null> URL referente à imagem de perfil do usuário
///
/// **lat**: <Number> Latitude da posição do usuário
///
/// **lng**: <Number> Longitude
///
/// **name**: <String> Nome do usuário
///
/// **time**: <Timestamp> Horário da última atualização da posição do usuário
///
/// **email**: <String> Email de cadastro do usuário
///
class UserData{
  String uid;
  String url;
  double lat;
  double lng;
  String name;
  Timestamp time;
  String email;

  UserData(Map<String, dynamic> data){
    uid = data['uid'];
    url = data['url'];
    lat = data['lat'];
    lng = data['lng'];
    name = data['name'];
    time = data['time'];
    email = data['email'];
  }

  Map<String, dynamic> toMap(){
    return <String, dynamic>{
      'uid': uid,
      'url': url,
      'lat': lat,
      'lng': lng,
      'name': name,
      'time': time,
      'email': email
    };
  }
}


//  Firebase Firestore User Structure
//
// 'uid':   [String]    User's unique ID
// 'url':   [String]    User's profile picture download URL <nullable>
// 'lat':   [Number]    User's last known latitude
// 'lng':   [Number]    User's last known longitude
// 'name':  [Number]    User's display name
// 'time':  [Timestamp] User's last location update timestamp
// 'email': [String]    User's email address