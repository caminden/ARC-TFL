import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';

const String ssd = "SSD MobileNet";

class HomeScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  HomeScreen(this.cameras);
  
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _HomeScreen();
  }
}

class _HomeScreen extends State<HomeScreen> {
  List<dynamic> _recognitions;
  int _imageHeight = 0;
  int _imageWidth = 0;
  String _model = "";

  loadModel() async {
    String result;

    switch(_model){
      case ssd: 
        result = await Tflite.loadModel(
          labels: "assets/labels.txt",
          model: "assets/ssd_mobilenet.tflite",
        );
    }
    print(result);
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text("Flutter ArCore/Tflite Demo"),
      ),
      body: _model == "" ? Container() : Stack(
        children: [],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){},
        child: Icon(Icons.photo_camera),
      ),
    );
  }
}
