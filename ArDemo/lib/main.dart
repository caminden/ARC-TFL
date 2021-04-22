import 'package:ArDemo/Homescreen.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

List<CameraDescription> cameras;

//test to initialize camera used for app
Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();
  try{
    cameras = await availableCameras();
  }
  catch(e){
    print("Error, $e.message");
  }
  runApp(MyApp());
}


//routing information to know homepage is HomeScreen, passing the cameras available as a parameter
class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ARCTFL',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(cameras),
 
    );
  }
}

