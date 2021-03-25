import 'dart:typed_data';

import 'package:ArDemo/Homescreen.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class ArScreen extends StatefulWidget {
    static const routeName = "/ArScreen";
    Uint8List bytes;
    ArScreen(this.bytes);
   //stateful widget type to allow for dynamic changes
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _ArScreen();
  }
}


class _ArScreen extends State<ArScreen>{
  ArCoreController con;
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    con.dispose();
  }

  onViewCreated(ArCoreController arCoreController){
    con = arCoreController;
    _addCube(con);
  }

  void _addCube(ArCoreController controller) async {
    final material = ArCoreMaterial(
      color: Color.fromARGB(120, 66, 134, 244),
      textureBytes: widget.bytes,
      metallic: 1.0,
    );
    final cube = ArCoreCube(
      materials: [material],
      size: vector.Vector3(0.5, 0.5, 0.5),
    );
    final node = ArCoreNode(
      shape: cube,
      position: vector.Vector3(-0.5, 0.5, -3.5),
    );

    controller.addArCoreNode(node);
  }
  
  @override
  Widget build(BuildContext context) {
    return ArCoreView(onArCoreViewCreated: onViewCreated,);
  }
}




