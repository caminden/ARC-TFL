import 'dart:io';
import 'package:ArDemo/Camera.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:math' as math;

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
  int view = 0;
  _Controller con;
  CameraController controller;
  XFile imageFile;
  Offset offset = Offset(0, 100);
  Offset imageOffset = Offset(0, 100);
  Alignment imageAlign = Alignment(0, 0);

  @override
  void initState() {
    super.initState();
    con = _Controller(this);
    if (widget.cameras == null || widget.cameras.length < 1) {
      print('No camera is found');
    } else {
      controller = new CameraController(
        widget.cameras[0],
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

  void render(fn) => setState(fn);

  //basic homescreen, no functionality as of now
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    Size screen = MediaQuery.of(context).size;
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
                imageFile = null;
              });
            },
          )
        ],
      ),
      body: view == 0
          ? Container()
          : Stack(
              children: <Widget>[
                con.Camera(),
                Positioned(
                  top: offset.dy - 90,
                  left: offset.dx,
                  child: Draggable(
                    childWhenDragging: Container(),
                    child: Container(
                        height: 110,
                        width: 110,
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.white))),
                    feedback: Container(
                        height: 110,
                        width: 110,
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.white))),
                    onDragEnd: (drag) {
                      setState(() {
                        offset = drag.offset;
                        print(drag.offset);
                      });
                    },
                  ),
                ),
                imageFile != null
                    ? Positioned(
                        top: imageOffset.dy - 90,
                        left: imageOffset.dx,
                        child: Draggable(
                            childWhenDragging: Container(),
                            child: Container(
                              clipBehavior: Clip.hardEdge,
                              height: 110,
                              width: 110,
                              decoration: BoxDecoration(
                                  image: DecorationImage(
                                      scale: 1.75,
                                      fit: BoxFit.none,
                                      alignment: imageAlign,
                                      image: FileImage(File(imageFile.path)))),
                            ),
                            feedback: Container(
                              height: 110,
                              width: 110,
                              decoration: BoxDecoration(
                                  image: DecorationImage(
                                      scale: 1.75,
                                      fit: BoxFit.none,
                                      alignment: imageAlign,
                                      image: FileImage(File(imageFile.path)))),
                            ),
                            onDragEnd: (drag) {
                              setState(() {
                                imageOffset = drag.offset;
                                print(drag.offset);
                              });
                            }),
                      )
                    : Container(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          XFile image = await controller.takePicture();
          setState(() {
            imageAlign = con.normalize(offset.dx, offset.dy);
            imageFile = image;
            imageOffset = offset;
            offset = Offset(0, 100);
            print(imageAlign.x);
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

  Widget Camera() {
    if (_state.controller == null || !_state.controller.value.isInitialized) {
      return Container();
    }

    var tmp = MediaQuery.of(_state.context).size;
    //print(tmp);
    var screenH = math.max(tmp.height, tmp.width);
    var screenW = math.min(tmp.height, tmp.width);
    tmp = _state.controller.value.previewSize;
    var previewH = math.max(tmp.height, tmp.width);
    var previewW = math.min(tmp.height, tmp.width);
    var screenRatio = screenH / screenW;
    var previewRatio = previewH / previewW;

    return OverflowBox(
      maxHeight:
          screenRatio > previewRatio ? screenH : screenW / previewW * previewH,
      maxWidth:
          screenRatio > previewRatio ? screenH / previewH * previewW : screenW,
      child: CameraPreview(_state.controller),
    );
  }

  Alignment normalize(x, y) {
    x = (x - 125) / 125;
    x = x.toDouble();
    print("X = " + x.toString());
    y = (y - 350) / 350;
    y = y.toDouble();
    print("Y = " + y.toString());
    return Alignment(x, y);
  }
}
