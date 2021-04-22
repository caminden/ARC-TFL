import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'models/picture.dart';

class FirebaseController {
  static void initializeFlutterFire() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {}
  }

  static Future<int> getCount() async {
    DocumentSnapshot snap = await FirebaseFirestore.instance
        .collection("Count")
        .doc("groupCount")
        .get();
    print("Value: " + snap.data().values.first.toString());
    return snap.data().values.first;
  }

  static Future updateCount(int count) async {
    print("Update count");
    await FirebaseFirestore.instance
        .collection("Count")
        .doc("groupCount")
        .update({"groups": count});
  }

  static Future<Map<String, String>> addPicToStorage(
      {@required File image}) async {
    print("Start add Pic to Storage");
    String filePath = "${Picture.IMAGE_FOLDER}/arpics/${DateTime.now()}";
    await FirebaseStorage.instance.ref().child(filePath).putFile(image);
    var url = await FirebaseStorage.instance.ref(filePath).getDownloadURL();
    return {"url": url, "path": filePath};
  }

  static Future<String> addPicToVault(Picture p) async {
    print("Start add Pic ref to Vault");
    DocumentReference doc = await FirebaseFirestore.instance.collection("Pictures").add(p.serialize());
    return doc.id;
  }

  static Future<List<Map<String, String>>> getPics(String groupId) async {
    print("Fetching " + groupId);
    QuerySnapshot snap = await FirebaseFirestore.instance
        .collection("Pictures")
        .where("groupId", isEqualTo: groupId)
        .orderBy("timestamp", descending: true)
        .get();

    List<Map<String, String>> map = [];
    for(int i = 0; i < snap.size; i++){
      Map<String, String> pic = {snap.docs[i].data().values.elementAt(0) : snap.docs[i].data().values.elementAt(3)};
      map.add(pic);
    }
  return map;
  }
}
