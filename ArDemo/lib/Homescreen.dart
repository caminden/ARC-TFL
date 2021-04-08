import 'dart:io';
import 'dart:typed_data';
//import 'package:ArDemo/Camera.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

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
  ArCoreController arController;
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

  //void render(fn) => setState(fn);

  //basic homescreen, no functionality as of now
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text("Flutter ArCore/Tflite Demo"),
        actions: view < 4 ? [Container()] : <Widget>[
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
      floatingActionButton: view < 4 ? FloatingActionButton(
        onPressed: () async {
          controller.takePicture().then((XFile image) async {
            print(
                "==============================================================");
            print(
                "========================Picure Taken =========================");
            Uint8List bytes = await image.readAsBytes();
            con.bytes.add(bytes);
            setState(() {
              //ximageFile.add(image);
              view+=1;
              print(view);
              //imageAlign = con.normalize(offset.dx, offset.dy);
              //imageOffset = offset;
              //offset = Offset(0, 100);
            });
          });
        },
        child: Icon(Icons.photo_camera),
      ) : Container(),
    );
  }
}

class _Controller {
  _HomeScreen _state;
  _Controller(this._state);

  Map<String, ArCoreAugmentedImage> augmentedImageMap = Map();
  Map<String, Uint8List> imageMap = Map();

  List<Uint8List> bytes = [];

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
          child: Text("Picture " + view.toString() + " of 4")
        ),
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
    return ArCoreView(onArCoreViewCreated: _arCoreView);
  }

  _arCoreView(ArCoreController controller) {
    _state.arController = controller;
    _displayImage(_state.arController);
  }

  void _displayImage(ArCoreController controller) {
    /*final material = ArCoreMaterial(
      color: Color.fromARGB(120, 66, 134, 244),
      textureBytes: bytes.elementAt(1),
      metallic: 1.0,
    );
    final cube = ArCoreCube(
      materials: [material],
      size: vector.Vector3(0.5, 0.5, 0.5),
    );
    final sphere = ArCoreSphere(
      materials: [material],
      radius: 1,
      
    );*/

    final image = ArCoreImage(bytes: bytes.elementAt(0), height: 800, width: 800);  //front
    final image2 = ArCoreImage(bytes: bytes.elementAt(1), height: 800, width: 800); //right
    final image3 = ArCoreImage(bytes: bytes.elementAt(2), height: 800, width: 800);  //back
    final image4 = ArCoreImage(bytes: bytes.elementAt(3), height: 800, width: 800);  //left


    final node = ArCoreNode(
      rotation: vector.Vector4(0, 0, 90, -90),
      image: image,                       //node front
      position: vector.Vector3(-0.5, 0, -1),
    );
    final node1 = ArCoreNode(
      rotation: vector.Vector4(0, 0, 90, 90),
      image: image3,                       //node1 back
      position: vector.Vector3(0.8, 0, 0.30),
    );
    final node2 = ArCoreNode(
      rotation: vector.Vector4(90, 90, 90, 90),
      image: image2,                     //node2 right
      position: vector.Vector3(0.8, 0, -1),
    );
    final node3 = ArCoreNode(
      rotation: vector.Vector4(90, 90, -90, -90),
      image: image4,                     //node3 left
      position: vector.Vector3(-0.5, 0, 0.30),
    );

    controller.addArCoreNode(node);
    controller.addArCoreNode(node1);
    controller.addArCoreNode(node2);
    controller.addArCoreNode(node3);
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
