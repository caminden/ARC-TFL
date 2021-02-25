import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:camera/camera.dart';

class ArNode extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _ArNode();
  }
}

class _ArNode extends State<ArNode> {
  ArCoreController _controller;

  void render(fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    return ArCoreView(
      onArCoreViewCreated: _onArCoreViewCreated,
    );
  }

  void _onArCoreViewCreated(ArCoreController controller) {
    _controller = controller;
    _addSphere(_controller);
  }

  Future _addSphere(ArCoreController controller) async {
    final material = ArCoreMaterial(
      color: Colors.yellow,
      roughness: 1.0,
    );
    final sphere = ArCoreSphere(
      materials: [material],
      radius: 0.2,
    );
    final node = ArCoreNode(
      shape: sphere,
      position: vector.Vector3(0.0, 0, -3.0),
    );
    controller.addArCoreNode(node);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _controller.dispose();
    super.dispose();
  }

  /*
  void _onArCoreViewCreated(ArCoreController controller) {
    _controller = controller;
    _addSphere(_controller);
  }

  Future _addSphere(ArCoreController controller) async {
    controller.getTrackingState();
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
  }*/

}
