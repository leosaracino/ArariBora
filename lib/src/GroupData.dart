import 'package:cloud_firestore/cloud_firestore.dart';

/// Define uma class GroupData que facilita o acesso a dados de grupos.
///
/// Estrutura de um grupo no Firestore:
///
/// **uid**: <String> ID unico do grupo gerado pelo Firebase Auth
///
/// **url**: <String, null> URL referente à imagem de perfil do grupo
///
/// **name**: <String> Nome do grupo
///
/// **users**: <> Lista que contém os IDs únicos dos usuários que estão no grupo
class GroupData{
  String uid;
  String url;
  String name;
  List<dynamic> users;


  GroupData(Map<String, dynamic> data){
    uid = data['uid'];
    url = data['url'];
    name = data['name'];
    users = data["users"];
  }

  Map<String, dynamic> toMap(){
    return <String, dynamic>{
      'uid': uid,
      'url': url,
      'name': name,
      'users': users,
    };
  }
}


//  Firebase Firestore Group Structure
//
// 'uid':   [String]    Group's unique ID
// 'url':   [String]    Group's profile picture download URL <nullable>
// 'name':  [Number]    Group's display name
// 'users': [array]     Group's users unique IDs
