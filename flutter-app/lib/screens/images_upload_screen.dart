import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_howsfit/screens/get_viton_image.dart';
import 'package:flutter_howsfit/screens/preprocess.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../constants/address.dart';

class ImageUploader extends StatefulWidget {
  const ImageUploader({Key? key}) : super(key: key);

  @override
  State<ImageUploader> createState() => _ImageUploaderState();
}

class _ImageUploaderState extends State<ImageUploader> {
  File? _my_model;
  File? _my_cloth;
  File? _wanted_model;
  File? _wanted_cloth;

  String my_model_fname = "";
  String my_cloth_fname = "";
  String wanted_model_fname = "";
  String wanted_cloth_fname = "";

  Future getMyModel() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    setState(() {
      _my_model = File(pickedFile!.path);
      my_model_fname = _my_model!.path.split('/').last;
      print("My Try-On Image is ${my_model_fname}");
    });
  }

  Future getMyCloth() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    setState(() {
      _my_cloth = File(pickedFile!.path);
      my_cloth_fname = _my_cloth!.path.split('/').last;
      print("picked cloth is ${my_cloth_fname}");
    });
  }

  Future getWantedModel() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    setState(() {
      _wanted_model = File(pickedFile!.path);
      wanted_model_fname = _wanted_model!.path.split('/').last;
      print("Wanted Model Image is ${wanted_model_fname}");
    });
  }

  Future getWantedCloth() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    setState(() {
      _wanted_cloth = File(pickedFile!.path);
      wanted_cloth_fname = _wanted_cloth!.path.split('/').last;
      print("Wanted Cloth Image is ${wanted_cloth_fname}");
    });
  }

  Future<http.Response> uploadImage(File myModelFile, File myClothFile, File wantedModelFile, File wantedClothFile) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$SERVER_ADDRESS/upload'),
    );

    request.files.add(await http.MultipartFile.fromPath(
      'my_model',
      myModelFile.path,
    ));

    request.files.add(await http.MultipartFile.fromPath(
      'my_cloth',
      myClothFile.path,
    ));

    request.files.add(await http.MultipartFile.fromPath(
      'wanted_model',
      wantedModelFile.path,
    ));

    request.files.add(await http.MultipartFile.fromPath(
      'wanted_cloth',
      wantedClothFile.path,
    ));

    var response = await request.send();

    if (response.statusCode == 200) {
      print("Image Upload ");
      final responseData = await response.stream.transform(utf8.decoder).join();
      final jsonData = jsonDecode(responseData);
      print(jsonData["my_cloth_fname"]);
      print(jsonData["wanted_cloth_fname"]);
      my_cloth_fname = jsonData["my_cloth_fname"];
      wanted_cloth_fname = jsonData["wanted_cloth_fname"];
      Navigator.of(context).push(MaterialPageRoute(
          builder: (BuildContext context) => Preprocess(
                my_cloth_fname: my_cloth_fname,
                wanted_cloth_fname: wanted_cloth_fname,
              )));
    } else {
      print("Image Upload failed");
    }
    return await http.Response.fromStream(response);
  }

  @override
  Widget build(BuildContext context) {
    final _imageSize = MediaQuery.of(context).size.width / 2;
    dynamic _imageHeight = 204.8;
    dynamic _imageWidth = 153.6;

    return Scaffold(
      appBar: AppBar(
        title: Text("Select Images"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_my_cloth == null)
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
                              width: 2,
                              color: Theme.of(context).colorScheme.primary),
                          image: DecorationImage(
                              image: FileImage(File(_my_cloth!.path)),
                              fit: BoxFit.cover),
                        ),
                      ),
                    SizedBox(
                      height: 20.0,
                    ),
                    ElevatedButton(
                      onPressed: getMyCloth,
                      child: Text("내 옷 이미지 올리기"),
                    ),
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_my_model == null)
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
                              width: 2,
                              color: Theme.of(context).colorScheme.primary),
                          image: DecorationImage(
                              image: FileImage(File(_my_model!.path)),
                              fit: BoxFit.cover),
                        ),
                      ),
                    SizedBox(
                      height: 20.0,
                    ),
                    ElevatedButton(
                      onPressed: getMyModel,
                      child: Text("내 착샷 올리기"),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    if (_wanted_cloth == null)
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
                              width: 2,
                              color: Theme.of(context).colorScheme.primary),
                          image: DecorationImage(
                              image: FileImage(File(_wanted_cloth!.path)),
                              fit: BoxFit.cover),
                        ),
                      ),
                    SizedBox(
                      height: 20.0,
                    ),
                    ElevatedButton(
                      onPressed: getWantedCloth,
                      child: Text("모델 옷 이미지 올리기"),
                    ),
                  ],
                ),
                Column(
                  children: [
                    if (_wanted_model == null)
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
                              width: 2,
                              color: Theme.of(context).colorScheme.primary),
                          image: DecorationImage(
                              image: FileImage(File(_wanted_model!.path)),
                              fit: BoxFit.cover),
                        ),
                      ),
                    SizedBox(
                      height: 20.0,
                    ),
                    ElevatedButton(
                      onPressed: getWantedModel,
                      child: Text("모델 착샷 올리기"),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(
              height: 20.0,
            ),
            ElevatedButton(
              onPressed: () => {
                uploadImage(_my_model!, _my_cloth!, _wanted_model!, _wanted_cloth!),
              },
              child: Text("Upload Image"),
            ),
          ],
        ),
      ),
    );
  }
}
