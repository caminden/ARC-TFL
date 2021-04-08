import 'dart:io';
import 'dart:typed_data';
//import 'package:ArDemo/Camera.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:tflite/tflite.dart';

const String ssd = "SSDMobileNet";

class HomeScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  HomeScreen(this.cameras);

  //stateful widget type to allow for dynamic changes
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _HomeScreen();
  }
}

//extention of stateful screen where widgets are placed
class _HomeScreen extends State<HomeScreen> {
  int view;
  _Controller con;
  CameraController controller;
  //List<CameraDescription> cameras;

  //variables for making cropped draggable
  //List<XFile> ximageFile = []; //for camera FileImage(File(imageFile.path))))
  Offset offset = Offset(0, 100);
  //Offset imageOffset = Offset(0, 100);
  //Alignment imageAlign = Alignment(0, 0);

  @override
  void initState() {
    super.initState();
    view = 0;
    con = _Controller(this);
    print("Start init");
    loadModel();

    if (widget.cameras == null || widget.cameras.length < 1) {
      print('No camera is found');
    } else {
      controller = new CameraController(
        widget.cameras.first,
        ResolutionPreset.high,
      );
      controller.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});
      });
    }
  }

  loadModel() async {
    String model = await Tflite.loadModel(
        model: "assets/ssd_mobilenet.tflite", labels: "assets/labels.txt");
    print("Model loaded, returned $model");
  }

  //void render(fn) => setState(fn);

  //basic homescreen, no functionality as of now
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text("Flutter ArCore/Tflite Demo"),
        actions: view < 4
            ? [Container()]
            : <Widget>[
                IconButton(
                  icon: Icon(Icons.adb),
                  onPressed: () {
                    setState(() {
                      view == 4 ? view = 5 : view = 4;
                      //offset = Offset(0, 100);
                      //ximageFile = null;
                    });
                  },
                )
              ],
      ),
      body: con.chooseBody(view),
      floatingActionButton: view < 4
          ? FloatingActionButton(
              onPressed: () async {
                controller.takePicture().then((XFile image) async {
                  print(
                      "==============================================================");
                  print(
                      "========================Picure Taken =========================");
                  Uint8List bytes = await image.readAsBytes();
                  con.bytes.add(bytes);
                  print("bytes captured, start tflite");
                  List<dynamic> recogs =
                      await Tflite.detectObjectOnImage(path: image.path);
                  List<dynamic> objects = [];
                  recogs.map((e) {
                    var r = e["detectedClass"];
                    objects.add(r);
                    //print(r.toString());
                  }).toList();
                  con.imageRecognitions.add(objects);
                  print("View " + view.toString() + " has " + con.imageRecognitions.elementAt(view).toString() + " recognitions");
                  //con.recognitions.add(recogs.elementAt(0));
                  setState(() {
                    //ximageFile.add(image);
                    view += 1;
                    print(view);
                    //imageAlign = con.normalize(offset.dx, offset.dy);
                    //imageOffset = offset;
                    //offset = Offset(0, 100);
                  });
                });
              },
              child: Icon(Icons.photo_camera),
            )
          : Container(),
    );
  }
}

class _Controller {
  _HomeScreen _state;
  _Controller(this._state);

  List<Uint8List> bytes = [];
  List<List<dynamic>> imageRecognitions = [];
  ArCoreController arController;

  Widget chooseBody(int view) {
    if (view < 4) {
      return camera(view);
    } else if (view == 4) {
      return arView();
    } else
      return Container(
        child: Text("Paused"),
      );
  }

  Widget camera(int view) {
    if (_state.controller == null || !_state.controller.value.isInitialized) {
      return Container(child: Text("Sample text"));
    }

    return Stack(
      children: <Widget>[
        CameraPreview(_state.controller), //to display the camera
        Positioned(
            top: _state.offset.dy - 90,
            left: _state.offset.dx,
            child: Text("Picture " + view.toString() + " of 4", style: TextStyle(fontSize: 20, color: Colors.pink),)),
        /*_state.ximageFile == null
            ? Container()
            : Positioned(
                top: _state.imageOffset.dy - 90,
                left: _state.imageOffset.dx,
                child: Draggable(
                    childWhenDragging: Container(),
                    child: Container(
                      clipBehavior: Clip.hardEdge,
                      height: 150,
                      width: 150,
                      decoration: BoxDecoration(
                          image: DecorationImage(
                              scale: 2,
                              fit: BoxFit.none,
                              alignment: _state.imageAlign,
                              image: FileImage(File(_state.ximageFile.path)))),
                    ),
                    feedback: Container(
                      height: 150,
                      width: 150,
                      decoration: BoxDecoration(
                          image: DecorationImage(
                              scale: 2,
                              fit: BoxFit.none,
                              alignment: _state.imageAlign,
                              image: FileImage(File(_state.ximageFile.path)))),
                    ),
                    onDragEnd: (drag) {
                      _state.setState(() {
                        _state.imageOffset = drag.offset;
                        print(drag.offset);
                      });
                    }),
              )*/
      ],
    );
  }

  Widget arView() {
    return ArCoreView(
      onArCoreViewCreated: _arCoreView,
      enableTapRecognizer: true,
    );
  }

  _arCoreView(ArCoreController controller) {
    arController = controller;
    arController.onNodeTap = (name) => onTapHandler(name);
    arController.onPlaneTap = _displayImage;
  }

  void onTapHandler(name) {
    print("===========================TAP===============================");
    showDialog(
        context: _state.context,
        builder: (BuildContext context) => AlertDialog(
              content: Text("node tapped with $name"),
            ));
  }

  void _displayImage(List<ArCoreHitTestResult> hits) {
    print("===========================HIT===============================");
    final hit = hits.first;
    
    /*inal material = ArCoreMaterial(
      color: Color.fromARGB(120, 66, 134, 244),
      roughness: 1,
      metallic: 1.0,
    );
    final sphere = ArCoreSphere(
      materials: [material],
      radius: 1,
    );*/

    final image =
        ArCoreImage(bytes: bytes.elementAt(0), height: 800, width: 800); //front
    final image2 =
        ArCoreImage(bytes: bytes.elementAt(1), height: 800, width: 800); //right
    final image3 =
        ArCoreImage(bytes: bytes.elementAt(2), height: 800, width: 800); //back
    final image4 =
        ArCoreImage(bytes: bytes.elementAt(3), height: 800, width: 800); //left

    /*final node5 = ArCoreRotatingNode(
        shape: sphere,
        rotation: vector.Vector4(0, 0, 90, -90),
        name: imageRecognitions.elementAt(0).toString(),
        degreesPerSecond: 1,
        position: hit.pose.translation
        );*/

    final node = ArCoreNode(
      rotation: vector.Vector4(0, 0, 90, -90),
      image: image, //node front
      name: imageRecognitions.elementAt(0).toString(),
      position: hit.pose.translation + vector.Vector3(-0.5, 1, -1),
    );
    final node1 = ArCoreNode(
      rotation: vector.Vector4(0, 0, 90, 90),
      image: image3, //node1 back
      name: imageRecognitions.elementAt(2).toString(),
      position: hit.pose.translation + vector.Vector3(0.8, 1, 0.30),
    );
    final node2 = ArCoreNode(
      rotation: vector.Vector4(90, 90, 90, 90),
      image: image2, //node2 right
      name: imageRecognitions.elementAt(1).toString(),
      position: hit.pose.translation + vector.Vector3(0.8, 1, -1),
    );
    final node3 = ArCoreNode(
      name: imageRecognitions.elementAt(3).toString(),
      rotation: vector.Vector4(90, 90, -90, -90),
      image: image4, //node3 left
      position: hit.pose.translation + vector.Vector3(-0.5, 1, 0.30),
    );

    arController.addArCoreNode(node);
    arController.addArCoreNode(node1);
    arController.addArCoreNode(node2);
    arController.addArCoreNode(node3);
  }

  Alignment normalize(x, y) {
    x = (x - 100) / 100;
    x = x.toDouble();
    print("X = " + x.toString());
    y = (y - 335) / 235;
    y = y.toDouble();
    print("Y = " + y.toString());
    return Alignment(x, y);
  }
}
