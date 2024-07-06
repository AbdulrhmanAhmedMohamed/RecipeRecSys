import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:untitled1/prediction_result_page.dart';



class InsertAudioPage extends StatefulWidget {

  @override
  _InsertAudioPageState createState() => _InsertAudioPageState();
}

class _InsertAudioPageState extends State<InsertAudioPage> {
  final  SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled=false;
  String _wordsSpoken="";
  double _confidenceLevel=0;

  @override
  void initState(){
    super.initState();
    initSpeech();
  }
  void initSpeech() async{

    _speechEnabled = await _speechToText.initialize();
    setState(() {

    });
  }

  void _startListening() async{

    await _speechToText.listen(onResult:_onSpeecResult);
    setState(() {
      _confidenceLevel =0;
    });
  }

  void _stopListening () async{

    await _speechToText.stop();
    setState(() {

    });
  }

  void _onSpeecResult(result){

    print ("Result:" + result.recognizedWords);
    List<String> words = result.recognizedWords.split(' ');
    List<String> fiveWords = words.take(5).toList();
    print ([
      fiveWords[0].trim(),
      fiveWords[1].trim(),
      fiveWords[2].trim(),
      fiveWords[3].trim(),
      fiveWords[4].trim(),
    ]);
    setState(() {
      _wordsSpoken="${result.recognizedWords}";

      _confidenceLevel=result.confidence;
    });
  }
  bool _isLoading = false;
  String _prediction = '';
  Future<void> _submitForm() async {
    print ("Enter Submit Form");
    setState(() {
      _isLoading = true;
    });
    List<String> words = _wordsSpoken.split(' ');
    List<String> fiveWords = words.take(5).toList();
    print (fiveWords);
    // Post request to API
    final response = await http.post(
      Uri.parse('http://192.168.193.117:5000/predict'),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'ingredients': [
          fiveWords[0].trim(),
          fiveWords[1].trim(),
          fiveWords[2].trim(),
          fiveWords[3].trim(),
          fiveWords[4].trim(),
        ],
      }),

    );


    if (response.statusCode == 200) {
      // Parse the response body as a map
      final Map<String, dynamic> data = jsonDecode(response.body);
      print (data);

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
  Widget build(BuildContext context)  {



    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Text('Audio'),
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
                    Icons.mic,
                    size: 80,
                    color: Colors.blue,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Speak and you shall be answered!',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    _speechToText.isListening ? "Listening..." :
                    _speechEnabled ? "Tap the mic" : "Speech not available",
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      // Button text color
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      textStyle: TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator()
                        : Text(
                      'Cook',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        _wordsSpoken,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  if (_speechToText.isNotListening && _confidenceLevel > 0)
                    Text(
                      "Confidence: ${(_confidenceLevel * 100).toStringAsFixed(1)}%",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _speechToText.isListening ? _stopListening : _startListening,
        tooltip: 'Listen',
        child: Icon(
          _speechToText.isNotListening ? Icons.mic_off : Icons.mic,
          color: Colors.white,
        ),
      ),
    );

  }
}