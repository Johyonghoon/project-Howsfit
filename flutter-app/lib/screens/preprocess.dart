import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_howsfit/constants/address.dart';
import 'package:flutter_howsfit/screens/get_viton_image.dart';
import 'package:http/http.dart' as http;
import 'package:percent_indicator/linear_percent_indicator.dart';

class Preprocess extends StatefulWidget {
  final String my_cloth_fname;
  final String wanted_cloth_fname;

  const Preprocess({
    Key? key,
    required this.my_cloth_fname,
    required this.wanted_cloth_fname,
  }) : super(key: key);

  @override
  State<Preprocess> createState() => _PreprocessState();
}

class _PreprocessState extends State<Preprocess> {
  int preprocess_count = 0;

  @override
  void initState() {
    super.initState();
    clothMask();
    openpose();
    densepose();
    humanparse();
  }

  Future clothMask() async {
    print("cloth mask request");
    final request_mask = await http.post(
      Uri.parse('$SERVER_ADDRESS/cloth-mask'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'my_cloth_fname': widget.my_cloth_fname,
        'wanted_cloth_fname': widget.wanted_cloth_fname,
      }),
    );
    if (request_mask.statusCode == 200) {
      Map<String, dynamic> responseJson = jsonDecode(request_mask.body);
      print(responseJson['msg']);
      setState(() {
        preprocess_count++;
        agnostics();
      });
      print(preprocess_count);
    } else {
      print("cloth-masking is something wrong ");
    }
  }

  Future openpose() async {
    print("openpose request");
    final request_openpose = await http.post(
      Uri.parse('$SERVER_ADDRESS/openpose'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'my_cloth_fname': widget.my_cloth_fname,
        'wanted_cloth_fname': widget.wanted_cloth_fname,
      }),
    );
    if (request_openpose.statusCode == 200) {
      Map<String, dynamic> responseJson = jsonDecode(request_openpose.body);
      print(responseJson['msg']);
      setState(() {
        preprocess_count++;
        agnostics();
      });
      print(preprocess_count);
    } else {
      print("openpose is something wrong");
    }
  }

  Future densepose() async {
    print("densepose request");
    final request_densepose = await http.post(
      Uri.parse('$SERVER_ADDRESS/densepose'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'my_cloth_fname': widget.my_cloth_fname,
        'wanted_cloth_fname': widget.wanted_cloth_fname,
      }),
    );
    if (request_densepose.statusCode == 200) {
      Map<String, dynamic> responseJson = jsonDecode(request_densepose.body);
      print(responseJson['msg']);
      setState(() {
        preprocess_count++;
        agnostics();
      });
      print(preprocess_count);
    } else {
      print("densepose is something wrong");
    }
  }

  Future humanparse() async {
    print("humanparse request");
    final request_humanparse = await http.post(
      Uri.parse('$SERVER_ADDRESS/human-parse'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'my_cloth_fname': widget.my_cloth_fname,
        'wanted_cloth_fname': widget.wanted_cloth_fname,
      }),
    );
    if (request_humanparse.statusCode == 200) {
      Map<String, dynamic> responseJson = jsonDecode(request_humanparse.body);
      print(responseJson['msg']);
      setState(() {
        preprocess_count++;
        print(widget.my_cloth_fname);
        print(widget.wanted_cloth_fname);
        agnostics();
      });
      print(preprocess_count);
    } else {
      print("humanparse is something wrong");
    }
  }

  Future agnostics() async {
    if (preprocess_count == 4) {
      print("agnostics request");
      final request_agnostics = await http.post(
        Uri.parse('$SERVER_ADDRESS/agnostics'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'my_cloth_fname': widget.my_cloth_fname,
          'wanted_cloth_fname': widget.wanted_cloth_fname,
        }),
      );
      if (request_agnostics.statusCode == 200) {
        Map<String, dynamic> responseJson = jsonDecode(request_agnostics.body);
        print(responseJson['msg']);
        setState(() {
          preprocess_count++;
          navigation();
        });
        print(preprocess_count);
      } else {
        print("agnostics are something wrong ");
      }
    }
  }

  Future navigation() async {
    if (preprocess_count == 5) {
      print("Five Preprocesses are done");
      Navigator.of(context).push(
        MaterialPageRoute(
            builder: (BuildContext context) => GetVitonImage(
                  my_cloth_fname: widget.my_cloth_fname,
                  wanted_cloth_fname: widget.wanted_cloth_fname,
                )),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double percent = preprocess_count / 5;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              alignment: FractionalOffset(percent, 1 - percent),
              child: FractionallySizedBox(
                child: Image.asset(
                  'assets/icons/cycling_person.png',
                  width: 30.0,
                  height: 30.0,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            LinearPercentIndicator(
              padding: EdgeInsets.zero,
              percent: percent,
              lineHeight: 10,
              backgroundColor: Colors.black38,
              progressColor: Colors.indigo.shade900,
              width: MediaQuery.of(context).size.width,
            ),
          ],
        ),
      ),
    );
  }
}
