import 'dart:io';
import 'dart:typed_data';
import 'package:ArDemo/FirebaseController.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:tflite/tflite.dart';
import 'models/picture.dart';
import 'package:http/http.dart' as http;

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
  Offset offset = Offset(0, 100);
  int groupCount;

  @override
  void initState() {
    super.initState();
    view = 0;
    con = _Controller(this);
    FirebaseController.initializeFlutterFire();

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

  @override
  void dispose() {
    controller?.dispose();
    con.arController?.dispose();
    super.dispose();
  }

  loadModel() async {
    String model = await Tflite.loadModel(
        model: "assets/ssd_mobilenet.tflite", labels: "assets/labels.txt");
    print("Model loaded, returned $model");
  }

  getCount() async {
    groupCount = await FirebaseController.getCount();
  }

  //basic homescreen, no functionality as of now
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text("ARC&TFL"),
        actions: view < 4
            ? <Widget>[
                Text("Skip pics"),
                IconButton(
                  icon: Icon(Icons.arrow_forward),
                  onPressed: () async {
                    groupCount = await FirebaseController.getCount();
                    setState(() {
                      view = 6;
                    });
                  },
                ),
              ]
            : view == 4
                ? <Widget>[
                    IconButton(
                      icon: Icon(Icons.photo),
                      onPressed: () {
                        setState(() {
                          view = 6;
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.play_arrow_rounded),
                      onPressed: () {
                        setState(() {
                          view = 5;
                        });
                      },
                    )
                  ]
                : <Widget>[
                    IconButton(
                      icon: view == 6 ? Icon(Icons.note) : Icon(Icons.pause),
                      onPressed: () {
                        setState(() {
                          view = 4;
                        });
                      },
                    )
                  ],
      ),
      body: con.chooseBody(view),
      floatingActionButton: view < 4
          ? FloatingActionButton(
              onPressed: () async {
                showDialog(
                    context: context,
                    builder: (context) =>
                        Center(child: CircularProgressIndicator()));
                if (view == 0) {
                  print("Get starting count");
                  groupCount = await FirebaseController.getCount();
                }
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
                  }).toList();

                  con.stringRecogs.add(objects.toString());
                  //con.imageRecognitions.add(objects);
                  //print("View " + view.toString() + " has " + con.imageRecognitions.elementAt(view).toString() + " recognitions");
                  Map<String, String> pic =
                      await FirebaseController.addPicToStorage(
                          image: File(image.path));
                  Picture p = new Picture(
                    photoURL: pic["url"],
                    photoPath: pic["path"],
                    timestamp: DateTime.now(),
                    groupId: "group" + groupCount.toString(),
                    recogs: objects.toString(),
                  );
                  p.docId = await FirebaseController.addPicToVault(p);

                  if (view == 3) {
                    groupCount++;
                    await FirebaseController.updateCount(groupCount);
                  }
                  Navigator.pop(context);
                  //print(pic);
                  setState(() {
                    view += 1;
                    print(view);
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
  List<String> stringRecogs = [];
  ArCoreController arController;

  Widget chooseBody(int view) {
    if (view < 4) {
      return camera(view);
    } else if (view == 4) {
      return SingleChildScrollView(
        child: Container(
          width: MediaQuery.of(_state.context).size.width,
          height: MediaQuery.of(_state.context).size.height,
          child: Column(
            children: [
              Text(
                "Paused",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline),
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                alignment: Alignment.center,
                width: MediaQuery.of(_state.context).size.width - 25,
                child: Text(
                  "This is a page for pausing the AR display and also for providing information",
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Text(
                "Quick info",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline),
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                alignment: Alignment.center,
                width: MediaQuery.of(_state.context).size.width - 25,
                child: Text(
                  "The pictures you just took have been saved and run through a machine learning model. The model scanned for common recognitions in the images and saved them to this app.",
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Text(
                "How to use the app",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline),
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                alignment: Alignment.center,
                width: MediaQuery.of(_state.context).size.width - 25,
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                          text: "Click on the ",
                          style: TextStyle(color: Colors.black)),
                      WidgetSpan(child: Icon(Icons.play_arrow_rounded)),
                      TextSpan(
                          text:
                              " in the top right corner to switch to the AR display, or when in the AR display to switch back to this screen.",
                          style: TextStyle(color: Colors.black))
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                alignment: Alignment.center,
                width: MediaQuery.of(_state.context).size.width - 25,
                child: Text(
                  "When the AR display is up, scan around on the ground to generate a grid to place AR objects on.",
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                alignment: Alignment.center,
                width: MediaQuery.of(_state.context).size.width - 25,
                child: Text(
                  "After a grid generates, tap on the grid to place the AR display of the pictures taken. If you walk into the object you will see your pictures surrounding you in AR.",
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                alignment: Alignment.center,
                width: MediaQuery.of(_state.context).size.width - 25,
                child: Text(
                  "If you tap on each picture, you will see a window pop up with objects the machine learning model recognized.",
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Text(
                "Restarting",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline),
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                alignment: Alignment.center,
                width: MediaQuery.of(_state.context).size.width - 25,
                child: Text(
                  "If you pause after displaying the AR display, you will reset all objects placed down and grids generated.",
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                alignment: Alignment.center,
                width: MediaQuery.of(_state.context).size.width - 25,
                child: Text(
                  "At this time pictures are instance only, so you must close and reopen the app to take new pictures and pictures are lost after closing the app. Saving environments to display is a work in progress.",
                ),
              ),
            ],
          ),
        ),
      );
    } else if (view == 6) {
      return ListView.builder(
          itemCount: _state.groupCount,
          itemBuilder: (BuildContext context, int index) {
            return Card(
              child: ListTile(
                contentPadding: EdgeInsets.all(10),
                title: Text("Group" + index.toString()),
                trailing: SizedBox(
                  height: 10,
                ),
                onTap: () {
                  loadEnv(index);
                },
              ),
            );
          });
    } else {
      return arView();
    }
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
            child: Column(
              children: [
                Container(
                    width: MediaQuery.of(_state.context).size.width,
                    child: Text(
                      "Take 4 pictures of your surrounding to display in AR",
                      style: TextStyle(fontSize: 14, color: Colors.white),
                      softWrap: true,
                      textAlign: TextAlign.center,
                    )),
                Container(
                  width: MediaQuery.of(_state.context).size.width,
                  child: Text(
                    "Picture " + view.toString() + " of 4",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            )),
      ],
    );
  }

  loadEnv(int index) async {
    showDialog(
        context: _state.context,
        builder: (context) => Center(child: CircularProgressIndicator()));
    print("Selected " + index.toString());
    String searchKey = "group" + index.toString();
    List<Map<String, String>> pics;
    stringRecogs = [];

    List<Uint8List> newBytes = [];
    pics = await FirebaseController.getPics(searchKey);
    pics.forEach((pic) async {
      Uri uri = Uri.parse(pic.keys.first);
      Uint8List byte = await http.readBytes(uri);

      newBytes.add(byte);
      stringRecogs.add(pic.values.first);
    });
    bytes = newBytes;
    print("New env loaded");
    Navigator.pop(_state.context);
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
              content: Text("The model detected $name in this picture"),
            ));
  }

  void _displayImage(List<ArCoreHitTestResult> hits) {
    print("===========================HIT===============================");
    final hit = hits.first;

    if (bytes.length == 0) {
      showDialog(
          context: _state.context,
          builder: (BuildContext context) => AlertDialog(
                content: Text("Please select an environment"),
              ));
    }

    final image =
        ArCoreImage(bytes: bytes.elementAt(0), height: 800, width: 800); //front
    final image2 =
        ArCoreImage(bytes: bytes.elementAt(1), height: 800, width: 800); //right
    final image3 =
        ArCoreImage(bytes: bytes.elementAt(2), height: 800, width: 800); //back
    final image4 =
        ArCoreImage(bytes: bytes.elementAt(3), height: 800, width: 800); //left

    final node = ArCoreNode(
      rotation: vector.Vector4(0, 0, 90, -90),
      image: image, //node front
      name: stringRecogs.elementAt(0),
      position: hit.pose.translation + vector.Vector3(-0.5, 1, -1),
    );
    final node1 = ArCoreNode(
      rotation: vector.Vector4(0, 0, 90, 90),
      image: image3, //node1 back
      name: stringRecogs.elementAt(2),
      position: hit.pose.translation + vector.Vector3(0.8, 1, 0.30),
    );
    final node2 = ArCoreNode(
      rotation: vector.Vector4(90, 90, 90, 90),
      image: image2, //node2 right
      name: stringRecogs.elementAt(1),
      position: hit.pose.translation + vector.Vector3(0.8, 1, -1),
    );
    final node3 = ArCoreNode(
      name: stringRecogs.elementAt(3),
      rotation: vector.Vector4(90, 90, -90, -90),
      image: image4, //node3 left
      position: hit.pose.translation + vector.Vector3(-0.5, 1, 0.30),
    );

    arController.addArCoreNode(node);
    arController.addArCoreNode(node1);
    arController.addArCoreNode(node2);
    arController.addArCoreNode(node3);
  }
}
