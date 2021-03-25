import 'dart:io';
import 'dart:typed_data';
//import 'package:ArDemo/Camera.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

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
  ScreenshotController screenshotController = ScreenshotController();
  XFile ximageFile; //for camera FileImage(File(imageFile.path))))
  Offset offset = Offset(0, 100);
  Offset imageOffset = Offset(0, 100);
  Alignment imageAlign = Alignment(0, 0);
  static GlobalKey previewContainer = new GlobalKey();

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

  @override
  void dispose() {
    // TODO: implement dispose
    con.arController.dispose();
    super.dispose();
  }

  //basic homescreen, no functionality as of now
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    Size screen = MediaQuery.of(context).size;
    return RepaintBoundary(
      key: previewContainer,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Flutter ArCore/Tflite Demo"),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.adb),
              onPressed: () {
                setState(() {
                  view == 0 ? view = 1 : view = 0;
                  offset = Offset(0, 100);
                  //imageFile = null;
                });
              },
            )
          ],
        ),
        body: view == 0
            ? Container()
            : Stack(
                children: <Widget>[
                  CameraPreview(controller), //to display the camera
                  Positioned(
                    top: offset.dy - 90,
                    left: offset.dx,
                    child: Draggable(
                      childWhenDragging: Container(),
                      child: Container(
                          height: 150,
                          width: 150,
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.blue))),
                      feedback: Container(
                          height: 150,
                          width: 150,
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.blue))),
                      onDragEnd: (drag) {
                        setState(() {
                          offset = drag.offset;
                          Alignment n = con.normalize(drag.offset.dx, drag.offset.dy);
                          print(drag.offset);
                        });
                      },
                    ),
                  ),
                  ximageFile == null ? Container() : 
                  Positioned(
                    top: imageOffset.dy - 90,
                    left: imageOffset.dx,
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
                                  alignment: imageAlign,
                                  image: FileImage(File(ximageFile.path)))),
                        ),
                        feedback: Container(
                          height: 150,
                          width: 150,
                          decoration: BoxDecoration(
                              image: DecorationImage(
                                  scale: 2,
                                  fit: BoxFit.none,
                                  alignment: imageAlign,
                                  image: FileImage(File(ximageFile.path)))),
                        ),
                        onDragEnd: (drag) {
                          setState(() {
                            imageOffset = drag.offset;
                            print(drag.offset);
                          });
                        }),
                  )
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            controller.takePicture().then((XFile image) {
              print(
                  "==============================================================");
              print(
                  "========================Picure Taken =========================");
              setState(() {
                ximageFile = image;
                imageAlign = con.normalize(offset.dx, offset.dy);
                imageOffset = offset;
                offset = Offset(0, 100);
              });
              print(File(ximageFile.path).toString());
              final result =
                  ImageGallerySaver.saveFile(File(ximageFile.path).toString());
            });
          },
          child: Icon(Icons.photo_camera),
        ),
      ),
    );
  }
}

class _Controller {
  _HomeScreen _state;
  _Controller(this._state);
  Map<String, ArCoreAugmentedImage> augmentedImageMap = Map();
  ArCoreController arController;
  Map<String, Uint8List> imageMap = Map();

  Widget Camera() {
    if (_state.controller == null || !_state.controller.value.isInitialized) {
      return Container(child: Text("Sample text"));
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
      child: ArCoreView(
          onArCoreViewCreated: _arCoreView,
          type: ArCoreViewType.AUGMENTEDIMAGES),
      //CameraPreview(_state.controller),
    );
  }

  _arCoreView(ArCoreController controller) {
    arController = controller;
    //controller.onTrackingImage = _handleTracking;
    //loadImages();
  }
  /*
  loadImages() async {
    if(_state.imageFile != null){
      imageMap["${_state.imageFile.name}"] = await _state.imageFile.readAsBytes();
      arController.loadMultipleAugmentedImage(bytesMap: imageMap);
    }
  }

  _handleTracking(ArCoreAugmentedImage augImage){
    if(!augmentedImageMap.containsKey(augImage.name)){
      augmentedImageMap[augImage.name] = augImage;
      _addSphere(augImage, augImage.name);
    }
  }

  Future _addSphere(ArCoreAugmentedImage augmentedImage, String imgName) async {
    final material = ArCoreMaterial(
      color: Color.fromARGB(155, 66, 134, 244),   
      metallic: 1.0,
    );

    final sphere = ArCoreSphere(
      materials: [material],
      radius: augmentedImage.extentX / 2,
    );

    final node = ArCoreNode(
      shape: sphere,
    );

    arController.addArCoreNodeToAugmentedImage(node, augmentedImage.index);
  }
  */

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

/* this is to display an image at a certain position, also draggable

*/

//this is to take a picture
/*
screenshotController
                .capture(delay: Duration(milliseconds: 20))
                .then((Uint8List image) async {
              print(
                  "==============================================================");
              print(
                  "========================Picure Taken =========================");
              setState(() {
                imageFile = image;
                imageAlign = con.normalize(offset.dx, offset.dy);
                imageOffset = offset;
                offset = Offset(0, 100);
                //print(imageAlign.x);
              });
              final result = await ImageGallerySaver.saveImage(imageFile);
            });     
*/

/*
RenderRepaintBoundary boundary =
                previewContainer.currentContext.findRenderObject();
            ui.Image image = await boundary.toImage();
            ByteData bytes = await image.toByteData(format: ui.ImageByteFormat.png);
            Uint8List imageByteList = bytes.buffer.asUint8List();
            final result = await ImageGallerySaver.saveImage(imageByteList);
*/
