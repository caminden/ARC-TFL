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

  XFile ximageFile; //for camera FileImage(File(imageFile.path))))
  Offset offset = Offset(0, 100);
  Offset imageOffset = Offset(0, 100);
  Alignment imageAlign = Alignment(0, 0);


  @override
  void initState() {
    super.initState();
    view = 2;
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
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.adb),
            onPressed: () {
              setState(() {
                view == 0 ? view = 1 : view = 0;
                offset = Offset(0, 100);
                ximageFile = null;
              });
            },
          )
        ],
      ),
      body: con.chooseBody(view),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          controller.takePicture().then((XFile image) async {
            print(
                "==============================================================");
            print(
                "========================Picure Taken =========================");
            con.bytes = await image.readAsBytes();
            setState(() {
              ximageFile = image;
              imageAlign = con.normalize(offset.dx, offset.dy);
              imageOffset = offset;
              offset = Offset(0, 100);
            });
          });
        },
        child: Icon(Icons.photo_camera),
      ),
    );
  }
}

class _Controller {
  _HomeScreen _state;
  _Controller(this._state);

  Map<String, ArCoreAugmentedImage> augmentedImageMap = Map();
  Map<String, Uint8List> imageMap = Map();

  Uint8List bytes;

  Widget chooseBody(int view) {
    if (view == 0) {
      return camera();
    } else if (view == 1) {
      return arView();
    } else
      return Container();
  }

  Widget camera() {
    if (_state.controller == null || !_state.controller.value.isInitialized) {
      return Container(child: Text("Sample text"));
    }

    return Stack(
      children: <Widget>[
        CameraPreview(_state.controller), //to display the camera
        Positioned(
          top: _state.offset.dy - 90,
          left: _state.offset.dx,
          child: Draggable(
            childWhenDragging: Container(),
            child: Container(
                height: 150,
                width: 150,
                decoration:
                    BoxDecoration(border: Border.all(color: Colors.blue))),
            feedback: Container(
                height: 150,
                width: 150,
                decoration:
                    BoxDecoration(border: Border.all(color: Colors.blue))),
            onDragEnd: (drag) {
              _state.setState(() {
                _state.offset = drag.offset;
                Alignment n = normalize(drag.offset.dx, drag.offset.dy);
                print(drag.offset);
              });
            },
          ),
        ),
        _state.ximageFile == null
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
              )
      ],
    );
  }

  Widget arView() {
    return ArCoreView(onArCoreViewCreated: _arCoreView);
  }

  _arCoreView(ArCoreController controller) {
    _state.arController = controller;
    _addCube(_state.arController);
  }

  void _addCube(ArCoreController controller) {
    final material = ArCoreMaterial(
      color: Color.fromARGB(120, 66, 134, 244),
      textureBytes: bytes,
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
