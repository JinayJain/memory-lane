import 'dart:io';

import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:path_provider/path_provider.dart';

class ViewPage extends StatefulWidget {
  const ViewPage({super.key, required this.imagePath});

  final String imagePath;

  @override
  State<ViewPage> createState() => _ViewPageState();
}

class _ViewPageState extends State<ViewPage> {
  String _loadingState = "Loading...";
  String? _modelUrl;

  // make api call when page loads
  Future<void> _processImage() async {
    final image = await FlutterExifRotation.rotateImage(path: widget.imagePath);
    var compressed = await FlutterImageCompress.compressWithFile(
      image.path,
      minWidth: 2048,
      minHeight: 2048,
      quality: 50,
    );

    final apiUrl = Uri.parse("https://jjain.loca.lt");
    var request = http.MultipartRequest("POST", apiUrl);

    if (compressed == null) {
      print("Failed to compress image");
      return;
    }

    request.files.add(await http.MultipartFile.fromBytes(
      "data",
      compressed,
      filename: "image.jpg",
    ));

    if (!mounted) return;
    setState(() {
      _loadingState = "Processing image...";
    });

    var response = await request.send();

    if (response.statusCode == 200) {
      print("Success");
      // save the response to a file

      if (!mounted) return;
      setState(() {
        _loadingState = "Downloading model...";
      });

      final model = await response.stream.toBytes();

      final tempFolder = await getTemporaryDirectory();

      final modelFile = File("${tempFolder.path}/model.glb")
        ..createSync()
        ..writeAsBytesSync(model);

      print(
          "Saved to ${modelFile.path} with ${modelFile.lengthSync() / 1024} KB");

      if (mounted && context.mounted) {
        setState(() {
          _loadingState = "Loading model...";
          _modelUrl = modelFile.uri.toString();
        });
      }
    } else {
      print("Failed with ${response.statusCode}");

      var responseString = await response.stream.bytesToString();
      print(responseString);

      if (mounted && context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _processImage();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_modelUrl == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Image.memory(widget.photoBytes),
                // rounded borders

                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(children: [
                    Image.file(
                      File(widget.imagePath),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ]),
                ),
                Positioned.fill(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _loadingState,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return Scaffold(
        body: ModelViewer(
          src: _modelUrl!,
          ar: true,
          autoRotate: true,
          cameraControls: true,
        ),
      );
    }
  }
}
