import 'package:ArDemo/Camera.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
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
  List<dynamic> _recognitions;  //
  int _imageHeight = 0;         //height of camera view
  int _imageWidth = 0;          //widgth of camera view
  String _model = "";           //the TensorFlow model chosen for the object detection

  loadModel() async {
    String result;

    //if model selected is SDD, load the corresponding model and its labels from assets
    switch(_model){
        default: 
        result = await Tflite.loadModel(
          labels: "assets/labels.txt",
          model: "assets/ssd_mobilenet.tflite",
        );
        break;
    }
    print(result);
  }

  onSelect(model){
    setState(() {
    _model = model;
    });

    loadModel();
  }

  setRecognitions(recognitions, imgHeight, imgWidth){
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

  //basic homescreen, no functionality as of now
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text("Flutter ArCore/Tflite Demo"),
      ),
      body: _model == "" ? Container() : Stack(
        children: [
          Camera(widget.cameras, _model, setRecognitions),
          //this is where bounding box would go
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: onSelect("ssd"),
        child: Icon(Icons.photo_camera),
      ),
    );
  }
}
