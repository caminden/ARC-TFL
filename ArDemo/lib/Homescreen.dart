import 'package:ArDemo/ArNode.dart';
import 'package:ArDemo/BoundingBox.dart';
import 'package:ArDemo/Camera.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';
import 'dart:math' as math;
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
  ArCoreController arCoreController;
  List<dynamic> _recognitions; //
  int _imageHeight = 0; //height of camera view
  int _imageWidth = 0; //widgth of camera view
  String _model = ""; //the TensorFlow model chosen for the object detection
  int view = 0;

  loadModel() async {
    String result;

    //if model selected is SDD, load the corresponding model and its labels from assets
    switch (_model) {
      default:
        result = await Tflite.loadModel(
          labels: "assets/labels.txt",
          model: "assets/ssd_mobilenet.tflite",
        );
        break;
    }
    print(result);
  }

  onSelect(model) {
    setState(() {
      _model = model;
      view = view == 0 ? 1 : 0;
      //print("********************: " + view.toString());
    });
    loadModel();
  }

  setRecognitions(recognitions, imgHeight, imgWidth) {
    setState(() {
      _recognitions = recognitions;
      _imageHeight = imgHeight;
      _imageWidth = imgWidth;
    });
  }

  @override
  void initState() {
    super.initState();
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
        actions: <Widget>[IconButton(
          icon: Icon(Icons.remove_circle_outline),
          onPressed: (){setState(() {
            _model = "";
          });},
        )],
      ),
      body: _model == ""
          ? Container()
          : view == 0
              ? ArNode()//Container(child: Text("Home Page"),)
              : Stack(
                  children: [
                    Camera(widget.cameras, _model, setRecognitions, screen),
                    BndBox(
                        _recognitions == null ? [] : _recognitions,
                        math.max(_imageHeight, _imageWidth),
                        math.min(_imageHeight, _imageWidth),
                        screen.height,
                        screen.width,
                        _model),
                        /*ArNode(
                        _recognitions == null ? [] : _recognitions,
                        _imageHeight,
                        _imageWidth,
                        ),*/
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => onSelect("ssd"),
        child: Icon(Icons.photo_camera),
      ),
    );
  }
}
 /*
Stack(
                  children: [
                    Camera(widget.cameras, _model, setRecognitions),
                    BndBox(
                        _recognitions == null ? [] : _recognitions,
                        math.max(_imageHeight, _imageWidth),
                        math.min(_imageHeight, _imageWidth),
                        screen.height,
                        screen.width,
                        _model),
                        /*ArNode(
                        _recognitions == null ? [] : _recognitions,
                        _imageHeight,
                        _imageWidth,
                        ),*/
                  ],
                )
                */
