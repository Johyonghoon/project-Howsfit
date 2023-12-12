import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';

import '../constants/address.dart';

class GetVitonImage extends StatefulWidget {
  final my_cloth_fname;
  final wanted_cloth_fname;

  const GetVitonImage({
    Key? key,
    this.my_cloth_fname,
    this.wanted_cloth_fname,
  }) : super(key: key);

  @override
  State<GetVitonImage> createState() => _GetVitonImageState();
}

class _GetVitonImageState extends State<GetVitonImage> {
  File? _viton;

  void initState() {
    super.initState();
    getVitonImage();
  }

  Future getVitonImage() async {
    // test
    final response_viton = await http.post(
      Uri.parse('$SERVER_ADDRESS/viton'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'my_cloth_fname': widget.my_cloth_fname,
        'wanted_cloth_fname': widget.wanted_cloth_fname,
      }),
    );

    if (response_viton.statusCode == 200) {
      print('Get VITON Image successfully');
      final Map<String, dynamic> data = json.decode(response_viton.body);
      final String imageBase64 = data['image'];
      final viton_fname = data['fname'];

      final decodedImage = base64.decode(imageBase64);
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/${viton_fname}';
      print(filePath);
      final imageFile = File(filePath);
      await imageFile.writeAsBytes(decodedImage);

      setState(() {
        _viton = imageFile;
      });
    } else {
      print('Failed to upload image ${response_viton.statusCode}');
    }
  }

  void onButtonPressed() {
    Navigator.popUntil(context, ModalRoute.withName('/upload'));
  }

  @override
  Widget build(BuildContext context) {
    final _imageSize = MediaQuery.of(context).size.width / 2;
    dynamic _imageHeight = 409.6;
    dynamic _imageWidth = 307.2;

    return Scaffold(
      appBar: AppBar(
        title: Text("가상 시착"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_viton == null)
              Container(
                constraints: BoxConstraints(
                  maxHeight: _imageHeight,
                  minWidth: _imageWidth,
                ),
                child: Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: _imageSize,
                  ),
                ),
              )
            else
              Container(
                height: _imageHeight,
                width: _imageWidth,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  border: Border.all(
                      width: 2, color: Theme.of(context).colorScheme.primary),
                  image: DecorationImage(
                      image: FileImage(_viton!), fit: BoxFit.cover),
                ),
              ),
            SizedBox(
              height: 20.0,
            ),
            ElevatedButton(
              onPressed: onButtonPressed,
              child: Text("처음으로 돌아가기"),
            ),
          ],
        ),
      ),
    );
  }
}
