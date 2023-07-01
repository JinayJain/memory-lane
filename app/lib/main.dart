import 'package:flutter/material.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

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
    final rawImage = await ImagePicker().pickImage(source: source);

    if (rawImage != null) {
      final image = await FlutterExifRotation.rotateImage(path: rawImage.path);

      final apiUrl = Uri.parse("https://jjain.loca.lt");
      var request = http.MultipartRequest("POST", apiUrl);
      request.files.add(await http.MultipartFile.fromPath("data", image.path));
      var response = await request.send();
      final responseData = await response.stream.toBytes();

      if (response.statusCode == 200) {
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              body: Center(
                child: Image.memory(responseData),
              ),
            ),
          ),
        );
      } else {
        print("Failed");
      }
    }
  }
}
