import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'AudioPage.dart';
import 'image.dart'; // Import the InsertImagePage
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'prediction_result_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(

      options: FirebaseOptions(apiKey: 'AIzaSyCoqCjIMAG8ElUeuWArOfKLVaj9AAWkFGE'
          , appId: '1:981887220075:android:ed9652222ba7e50dd9742e'
          , messagingSenderId: '981887220075'
          , projectId: 'image-242b2',
          storageBucket:'image-242b2.appspot.com'
      ));
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DishDelight',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<TextEditingController> controllers =
  List.generate(5, (_) => TextEditingController());

  bool _isLoading = false;
  String _prediction = '';

  Future<void> _submitForm() async {
    setState(() {
      _isLoading = true;
    });

    // Post request to API
    final response = await http.post(
      Uri.parse('http://192.168.193.117:5000/predict'),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'ingredients': [
          controllers[0].text.trim(),
          controllers[1].text.trim(),
          controllers[2].text.trim(),
          controllers[3].text.trim(),
          controllers[4].text.trim(),
        ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Colors.lightBlue.shade300, Colors.lightBlue.shade600], // Brown gradient
            ),
          ),
          child: AppBar(
            leading: Builder(
              builder: (BuildContext context) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () {
                      Scaffold.of(context).openDrawer();
                    },
                    child: Image.network(
                      "https://cdn-icons-png.flaticon.com/512/5141/5141534.png",
                      height: 30,
                      width: 30,
                    ),
                  ),
                );
              },
            ),
            backgroundColor: Colors.transparent,
            elevation: 0, // Remove appbar shadow
            title: Text(
              'DishDelight',
              style: GoogleFonts.aBeeZee(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            Container(
              height: 80.0, // Set your desired height here
              decoration: BoxDecoration(
                color: Colors.blueAccent,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20,8,0,8),
                  child: Text(
                    'Other options',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                leading: Icon(Icons.image, color: Colors.blue),
                title: Text('Insert Image'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => InsertImagePage()),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                leading: Icon(Icons.multitrack_audio, color: Colors.blue),
                title: Text('Insert Audio'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => InsertAudioPage()),
                  );
                },
              ),
            ),
          ],
        ),
      )
      ,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade200, Colors.blue.shade50],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (int i = 1; i <= 5; i++)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: TextFormField(
                    controller: controllers[i - 1],
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  textStyle: TextStyle(color: Colors.white),
                  // Change to your preferred color
                ),
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text(
                  'Cook',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
