import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();

    final ImagePickerPlatform imagePickerImplementation =
        ImagePickerPlatform.instance;
    if (imagePickerImplementation is ImagePickerAndroid) {
      imagePickerImplementation.useAndroidPhotoPicker = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            onPressed: () => pickImage(ImageSource.camera),
            child: const Text('Capture Image'),
          ),
          FilledButton(
              onPressed: () => pickImage(ImageSource.gallery),
              child: const Text('Pick Image')),
        ],
      ),
    );
  }

  Future pickImage(ImageSource source) async {
    final rawImage = await ImagePicker().pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 50,
    );

    if (rawImage != null) {
      final image = await FlutterExifRotation.rotateImage(path: rawImage.path);

      final apiUrl = Uri.parse("https://jjain.loca.lt");
      var request = http.MultipartRequest("POST", apiUrl);
      request.files.add(await http.MultipartFile.fromPath("data", image.path));

      // print the request size, including the file
      print(request.contentLength);

      var response = await request.send();

      if (response.statusCode == 200) {
        print("Success");
        if (!context.mounted) return;
        // save the response to a file
        final modelBytes = await response.stream.toBytes();

        final tempFolder = await getApplicationDocumentsDirectory();

        final modelFile = File("${tempFolder.path}/model.glb")
          ..createSync()
          ..writeAsBytesSync(modelBytes);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              body: ModelViewer(
                src: modelFile.uri.toString(),
                ar: true,
                autoRotate: true,
                cameraControls: true,
              ),
            ),
          ),
        );
      } else {
        print("Failed with ${response.statusCode}");

        var responseString = await response.stream.bytesToString();
        print(responseString);
      }
    }
  }
}
