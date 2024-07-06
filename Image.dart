import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:untitled1/prediction_result_page.dart';

class InsertImagePage extends StatefulWidget {
  @override
  _InsertImagePageState createState() => _InsertImagePageState();
}

class _InsertImagePageState extends State<InsertImagePage> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String _prediction = '';
  Future<void> _submitForm(download) async {
    setState(() {
      _isLoading = true;
    });
    print("test");
    // Post request to API
    final response = await http.post(
      Uri.parse('http://192.168.193.117:5000/predictImage'),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'ImageURL':download
      }),
    );

    if (response.statusCode == 200) {
      // Parse the response body as a map
      final Map<String, dynamic> data = jsonDecode(response.body);
      // Extract the prediction string from the map
      final List<dynamic> predictionList = data['prediction'];
      if (predictionList.isNotEmpty) {
        setState(() {
          _prediction = predictionList[0].toString();
        });
        // Navigate to the prediction result page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PredictionResultPage(prediction: _prediction),
          ),
        );
      } else {
        setState(() {
          _prediction = 'No prediction available';
        });
      }
    } else {
      // Show error message
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Failed to get prediction. Please try again later.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }

    setState(() {
      _isLoading = false;
    });
  }
  Future<void> _uploadImage(XFile image) async {
    try {
      print('Starting image upload...');
      FirebaseStorage storage = FirebaseStorage.instanceFor(bucket: 'image-242b2.appspot.com');
      Reference ref = storage.ref().child('images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      UploadTask uploadTask = ref.putFile(File(image.path));

      TaskSnapshot taskSnapshot = await uploadTask;
      print('Upload complete. Getting download URL...');
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      print('Download URL: $downloadUrl');
      _submitForm(downloadUrl);
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      DocumentReference docRef = await firestore.collection('images').add({
        'url': downloadUrl,
        'uploaded_at': DateTime.now(),
      });

      String imageId = docRef.id;
      print('Image ID: $imageId');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image uploaded with ID: $imageId')));
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await _uploadImage(image);
    } else {
      print('No image selected.');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Insert Image'),
        backgroundColor:Colors.blue,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.blue.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.insert_photo,
                    size: 80,
                    color: Colors.blue,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Pssst, you can attach an image from your gallery too, no need to type!',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: Text('Pick an Image'),
                    style: ElevatedButton.styleFrom(// Button text color
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      textStyle: TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
