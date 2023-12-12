import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_howsfit/screens/get_viton_image.dart';
import 'package:flutter_howsfit/screens/images_upload_screen.dart';
import 'package:flutter_howsfit/screens/preprocess.dart';

void main() {
  runApp(
    MaterialApp(
      home: ImageUploader(),
      initialRoute: '/upload',
      routes: {
        '/upload': (context) => ImageUploader(),
        '/preprocess': (context) => Preprocess(my_cloth_fname: "", wanted_cloth_fname: ""),
        'viton': (context) => GetVitonImage(),
      },
    )
  );
}
