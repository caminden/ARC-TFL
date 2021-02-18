import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:camera/camera.dart';

class ArNode extends StatelessWidget {
  final List<dynamic> results;
  ArCoreController _controller;
  int imgH;
  int imgW;

  ArNode(this.results, this.imgH, this.imgW);

  @override
  Widget build(BuildContext context) {
    return ArCoreView(
      onArCoreViewCreated: _onArCoreViewCreated,
      enablePlaneRenderer: false,
    );
  }

  void _onArCoreViewCreated(ArCoreController controller) {
    _controller = controller;
    _addSphere(_controller);
  }

  Future _addSphere(ArCoreController controller) async {
    _placeNode().forEach((node) {
      controller.addArCoreNode(node);
    });
  }

  List<ArCoreNode> _placeNode() {
    //print("********************");
    //print(results.toString());
    
    return results.map((re) {
      final material = ArCoreMaterial(
        color: Colors.red,
      );

      final sphere = ArCoreSphere(
        materials: [material],
        radius: 0.2,
      );

      return ArCoreNode(
        shape: sphere,
        position: vector.Vector3(1.0, 1.0, 1.0),
      );
    }).toList();
  }
}
