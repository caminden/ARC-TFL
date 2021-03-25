import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

typedef void Callback(XFile ximageFile, Uint8List bytes);

class Camera extends StatefulWidget {
  final List<CameraDescription> cameras;
  final Callback setImage;

  Camera(this.cameras, this.setImage);


  @override
  State<StatefulWidget> createState(){
    return _CameraState();
  }
}

class _CameraState extends State<Camera> {
  CameraController controller;
  bool isDetecting = false;
  Offset offset = Offset(0, 100);
  XFile ximageFile;
  Offset imageOffset = Offset(0, 100);
  Alignment imageAlign = Alignment(0, 0);

  @override
  void initState() {
    super.initState();
    if (widget.cameras == null || widget.cameras.length < 1) {
      print('No camera is found');
    } else {
      trySetCameras();
    }
  }

  trySetCameras() {
    controller = new CameraController(
      widget.cameras[0],
      ResolutionPreset.high,
    );
    controller.initialize().then((_) {
      if (!mounted) {
        print("Camera not mounted");
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    controller.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller.value.isInitialized) {
      trySetCameras();
    }

    try {
      return Stack(
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
                  decoration:
                      BoxDecoration(border: Border.all(color: Colors.blue))),
              feedback: Container(
                  height: 150,
                  width: 150,
                  decoration:
                      BoxDecoration(border: Border.all(color: Colors.blue))),
              onDragEnd: (drag) {
                setState(() {
                  offset = drag.offset;
                  normalize(drag.offset.dx, drag.offset.dy);
                  print(drag.offset);
                });
              },
            ),
          ),
          ximageFile == null
              ? Container()
              : Positioned(
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
                ),
          /*Positioned(
            bottom: 0,
            right: 0,
            child: IconButton(
                icon: Icon(Icons.camera),
                onPressed: () async {
                  controller.takePicture().then((XFile image) async {
                    print(
                        "==============================================================");
                    print(
                        "========================Picure Taken =========================");
                    Uint8List bytes = await image.readAsBytes();
                    widget.setImage(image, bytes);
                    setState(() {
                      ximageFile = image;
                      imageAlign = normalize(offset.dx, offset.dy);
                      imageOffset = offset;
                      offset = Offset(0, 100);
                    });
                  });
                }),
          ),*/
        ],
      );
    } catch (e) {
      return Container();
    }
  }
}
