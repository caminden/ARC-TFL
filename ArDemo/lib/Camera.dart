import 'package:ArDemo/Homescreen.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';
import 'dart:math' as math;

typedef void Callback(List<dynamic> list, int h, int w);

class Camera extends StatefulWidget {
  final List<CameraDescription> cameras;
  final Callback setRecognitions;
  final String model;

  Camera(this.cameras, this.model, this.setRecognitions);

  @override
  State<StatefulWidget> createState() {
    return _Camera();
  }
}

class _Camera extends State<Camera> {
  CameraController controller;
  bool isDetecting = false;

  @override
  void initState() {
    super.initState();

    //test if camera has been selected
    if (widget.cameras == null || widget.cameras.length < 1) {
      print("No camera found");
    } else {
      //set camera to first in list and initialize
      controller = new CameraController(
        widget.cameras[0],
        ResolutionPreset.high,
      );
      controller.initialize()
          //everything here is run after Camera Controller has been initialized
          .then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});
        //send stream coming from camera into Tensorflow model
        controller.startImageStream((CameraImage img) {
          if (!isDetecting) {
            isDetecting = true;
            int startTime = new DateTime.now().millisecondsSinceEpoch;

            Tflite.detectObjectOnFrame(
                    bytesList: img.planes.map((plane) {
                      return plane.bytes;
                    }).toList(),
                    model: "SSDMobileNet",
                    imageHeight: img.height,
                    imageWidth: img.width,
                    imageMean: 127.5,
                    imageStd:  127.5,
                    numResultsPerClass: 1,
                    threshold: 0.4 //default is 0.1
                    )
                //this is run after all parameters are passed to tensorflow model
                //therefore we need to begin terminating
                .then((recognitions) {
              int endTime = new DateTime.now().millisecondsSinceEpoch;
              print("Detection time took ${endTime - startTime}");
              print(recognitions);
              widget.setRecognitions(recognitions, img.height, img.width);

              isDetecting = false;
            });
          }
        });
      });
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller.value.isInitialized) {
      return Container();
    }

    var tmp = MediaQuery.of(context).size;
    var screenH = math.max(tmp.height, tmp.width);
    var screenW = math.min(tmp.height, tmp.width);

    tmp = controller.value.previewSize;
    var previewH = math.max(tmp.height, tmp.width);
    var previewW = math.min(tmp.height, tmp.width);

    var screenRatio = screenH / screenW;
    var previewRatio = previewH / previewW;

    return OverflowBox(
      maxHeight:
          screenRatio > previewRatio ? screenH : screenW / previewW * previewH,
      maxWidth:
          screenRatio > previewRatio ? screenH / previewH * previewW : screenW,
      child: CameraPreview(controller),
    );
    // TODO: implement build
  }
}
