import 'package:app/view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String _modelUrl;

  @override
  void initState() {
    super.initState();

    final ImagePickerPlatform imagePickerImplementation =
        ImagePickerPlatform.instance;
    if (imagePickerImplementation is ImagePickerAndroid) {
      imagePickerImplementation.useAndroidPhotoPicker = true;
    }

    rootBundle.load("assets/example.glb").then((value) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Memory Lane",
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
        // add theming
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: ModelViewer(
              src: "assets/example.glb",
              alt: "Example 3D model",
              autoRotate: true,
              // maxCameraOrbit: "157.5deg 157.5deg auto",
              // minCameraOrbit: "22.5deg 22.5deg auto",
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                const Text(
                  "Relive your memories in immersive 3D",
                  style: TextStyle(
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => pickImage(ImageSource.camera),
                      icon: Icon(Icons.camera, size: 32),
                      label: Text("Camera"),
                    ),
                    SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () => pickImage(ImageSource.gallery),
                      icon: Icon(Icons.photo),
                      label: Text("Gallery"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future pickImage(ImageSource source) async {
    final rawImage = await ImagePicker().pickImage(source: source);

    if (mounted && context.mounted && rawImage != null) {
      Navigator.push(context, MaterialPageRoute(
        builder: (context) {
          return ViewPage(
            imagePath: rawImage.path,
          );
        },
      ));
    }
  }
}
