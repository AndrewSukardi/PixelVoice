import 'dart:io'; // Import untuk File manipulation
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart'; // Import flutter_tts
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'utils/request.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

const linkURL = 'http://103.82.92.216:8000/predict';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pixel Voice',
      theme: ThemeData(
        fontFamily: 'Roboto',
        primaryColor: const Color.fromARGB(255, 86, 142, 115),
      ),
      home: const SplashScreen(), // Menampilkan Splash Screen terlebih dahulu
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CameraPermissionScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set the background color
      body: Column(
        mainAxisAlignment: MainAxisAlignment
            .center, // This centers the column's children vertically
        children: [
          // Use an expanded widget to center the image vertically
          Expanded(
            child: Center(
              child: Image.asset(
                'assets/icon/logo.png', // Path to your image in the assets folder
                width: 150, // You can adjust the width as needed
                height: 150, // You can adjust the height as needed
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.only(bottom: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Text(
                //   "Pixel Voice",
                //   style: TextStyle(fontSize: 18),
                // ),
                // SizedBox(height: 10),
                Text(
                  "Andrew - Jayagatha - Sebastian",
                  style: TextStyle(fontSize: 12),
                ),
                SizedBox(height: 10),
                Text(
                  "Binus University 2025",
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CameraPermissionScreen extends StatefulWidget {
  const CameraPermissionScreen({super.key});

  @override
  CameraPermissionScreenState createState() => CameraPermissionScreenState();
}

class CameraPermissionScreenState extends State<CameraPermissionScreen>
    with TickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  final FlutterTts _flutterTts = FlutterTts();
  final List<String> _imagePaths = [];
  bool _isLoading = false; // Status loading untuk menampilkan spinner
  final AudioPlayer _audioPlayer = AudioPlayer(); // AudioPlayer instance
  late stt.SpeechToText _speechToText;
  bool _isListening = false;
  ValueNotifier<bool> isListeningNotifier = ValueNotifier<bool>(false);
  ValueNotifier<String> recognizedTextNotifier = ValueNotifier<String>('');
  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
    _checkPermissionAndInitializeCamera();
  }

  // Function to start/stop speech recognition when button is held
  void _startListening(String displayText, BuildContext modalContext) async {
    await _speechToText.stop();
    if (!_isListening) {
      // Initialize speech recognition
      bool available = await _speechToText.initialize();

      if (available) {
        await _audioPlayer.play(AssetSource('sound/start_voice_capture.wav'));
        setState(() {
          _isListening = true;
          isListeningNotifier.value = true; // Start listening
        });

        // Start listening to speech input
        await _speechToText.listen(
          localeId: "id_ID", // Set Indonesian language
          onResult: (result) {
            recognizedTextNotifier.value = result.recognizedWords;
            String command = result.recognizedWords.toLowerCase();

            // Process command only when it's fully recognized

            if (result.hasConfidenceRating && result.confidence > 0.5) {
              _audioPlayer.play(AssetSource('sound/start_voice_capture.wav'));
              Set<String> commandSet = command
                  .trim() // Remove leading and trailing whitespaces
                  .toLowerCase() // Convert to lowercase
                  .replaceAll(RegExp(r'[^a-z0-9\s]'),
                      '') // Remove all non-alphanumeric characters except spaces
                  .split(' ') // Split the string into a list of words
                  .toSet(); // Convert the list to a Set
              print("aaadawdadw $commandSet");
              print(commandSet);
              // Check command and perform actions
              if ((commandSet.any((word) => word.contains("suara")) ||
                      commandSet.any((word) => word.contains("prediksi"))) &&
                  (commandSet.any((word) =>
                          word.contains("foto") ||
                          commandSet.any((word) => word.contains("gambar"))) ||
                      commandSet.any((word) => word.contains("poto")) ||
                      commandSet.any((word) => word.contains("kamera")))) {
                _flutterTts.speak(
                    '$displayText dan mengambil ulang foto'); // Repeat the current text
                Future.delayed(const Duration(milliseconds: 1000), () {
                  Navigator.pop(
                      modalContext); // Close the modal after the delay
                });
              } else if (commandSet.any((word) => word.contains("suara")) ||
                  commandSet.any((word) => word.contains("prediksi"))) {
                _flutterTts.speak(displayText); // Repeat the current text
              } else if (commandSet.any((word) =>
                      word.contains("foto") ||
                      commandSet.any((word) => word.contains("gambar"))) ||
                  commandSet.any((word) => word.contains("poto")) ||
                  commandSet.any((word) => word.contains("kamera"))) {
                _flutterTts.speak("mengambil ulang foto");
                Future.delayed(const Duration(milliseconds: 1000), () {
                  Navigator.pop(
                      modalContext); // Close the modal after the delay
                }); // Close the modal
              }

              // Once done, stop listening and update UI
              if (mounted) {
                setState(() {
                  _isListening = false;
                  isListeningNotifier.value = false; // Update the notifier
                });
              }
            }
          },
        );
      } else {
        return;
      }
    }
  }

  void _stopListening() async {
    if (_isListening) {
      setState(() {
        _isListening = false;
        // Toggle the listening state using the ValueNotifier
        isListeningNotifier.value = false;
      });
      await _speechToText.stop();
    }
  }

  Future<void> _checkPermissionAndInitializeCamera() async {
    PermissionStatus status = await Permission.camera.request();
    PermissionStatus statusmic = await Permission.microphone.request();
    if (status.isGranted && statusmic.isGranted) {
      await _initializeCamera();
    } else {
      _showPermissionDeniedDialog();
    }
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _controller = CameraController(
        _cameras!.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _controller!.initialize();

      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Izin Tidak Diberikan'),
          content: const Text('Camera diperlukan untuk menjalankan aplikasi'),
          actions: [
            TextButton(
              child: const Text('KELUAR'),
              onPressed: () {
                Navigator.of(context).pop();
                exit(0);
              },
            ),
            TextButton(
              child: const Text('COBA LAGI'),
              onPressed: () {
                Navigator.of(context).pop();
                _checkPermissionAndInitializeCamera();
              },
            ),
          ],
        );
      },
    );
  }

  void _takePicture() async {
    _isListening = false;
    if (!_controller!.value.isInitialized) {
      return;
    }
    await _flutterTts.setLanguage("id-ID");

    // Play the shutter sound

    // Proceed with taking the picture
    await _controller!.setFlashMode(FlashMode.auto);
    final XFile rawImage = await _controller!.takePicture();
    await _playShutterSound();

    // Convert the image to base64
    final imageFile = File(rawImage.path);
    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes); // Base64 encode the image
    // Print the base64 encoded string
    // Tampilkan dialog preview dengan spinner sebelum resize dimulai
    setState(() {
      _isLoading = true; // Set loading status to true
    });

    _flutterTts.speak("Melakukan Prediksi Gambar");
    _showImagePreviewDialog();

    // Proses resize gambar setelah dialog ditampilkan
    await _deleteOldImages();

    Map<String, dynamic>? result = await makePostRequest(base64Image, linkURL);
    // Update state setelah resize selesai
    setState(() {
      _isLoading = false; // Set loading status to false once done
    });

    // Update dialog dengan gambar dan teks prediksi
    _updateImagePreviewDialog(
        result?['Generated_Translated_Caption'], result?['status']);

    if (result?['Generated_Translated_Caption'] != null) {
      await _flutterTts.speak(result?['Generated_Translated_Caption']);
    } else {
      await _flutterTts.speak('Gagal Melakukan Prediksi');
    }
  }

  // Function to play the shutter sound
  Future<void> _playShutterSound() async {
    await _audioPlayer.play(AssetSource('sound/shutter.wav'));
  }

  Future<void> _deleteOldImages() async {
    for (String path in _imagePaths) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
    _imagePaths.clear();
  }

  // Fungsi untuk menampilkan dialog dengan spinner
  void _showImagePreviewDialog([String? kata, int? status]) {
    recognizedTextNotifier.value = '';
    const String waiting = "Melakukan Prediksi Gambar";
    String displayText = kata ?? "Gagal Melakukan Prediksi";

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext modalContext) {
        // Use a separate context here
        // AnimationController to control the slide animation
        AnimationController animationController = AnimationController(
          duration: const Duration(milliseconds: 300), // Slide duration
          vsync: this, // You need to use the TickerProvider
        );

        // Tween for sliding in from the bottom
        Animation<Offset> slideAnimation = Tween<Offset>(
          begin: const Offset(0, 1), // Start from the bottom
          end: const Offset(0, 0), // End at the top (normal position)
        ).animate(CurvedAnimation(
          parent: animationController,
          curve: Curves.easeOut, // Smooth easing effect
        ));

        // Start the slide animation
        animationController.forward();

        return SlideTransition(
          position: slideAnimation,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).orientation == Orientation.portrait
                ? MediaQuery.of(context).size.height *
                    0.35 // Height for portrait
                : MediaQuery.of(context).size.height *
                    0.55, // Height for landscape
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top gray bar that stays at the top
                Container(
                  height: 3,
                  width: MediaQuery.of(context).size.width * 0.45,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                // Space between top bar and content

                // Use Expanded to make sure the content is centered properly
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // The loading state or result text
                      if (_isLoading && status == null) ...[
                        const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color.fromARGB(255, 86, 142, 115))),
                        const SizedBox(height: 30),
                        const Text(
                          waiting,
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ] else ...[
                        Text(
                          displayText,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
                if (!_isLoading) ...[
                  Padding(
                    padding: const EdgeInsets.only(),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.start, // Align items to the top
                      crossAxisAlignment:
                          CrossAxisAlignment.center, // Center horizontally
                      children: [
                        ValueListenableBuilder<String>(
                          valueListenable: recognizedTextNotifier,
                          builder: (context, recognizedText, child) {
                            if (recognizedText.isEmpty) {
                              return const SizedBox();
                            } else {
                              Future.delayed(const Duration(seconds: 20), () {
                                if (recognizedText.isNotEmpty) {
                                  recognizedTextNotifier.value = '';
                                }
                              });
                              return Column(
                                children: [
                                  Text(
                                    recognizedText, // Teks yang dikenali secara live
                                    style: const TextStyle(
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                        const SizedBox(
                            height: 10), // Add space between text and button
                        // Voice Input Button (Tap to Start/Stop Recording)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              // Toggle the listening state using the ValueNotifier
                              isListeningNotifier.value =
                                  !isListeningNotifier.value;

                              // If listening starts, begin speech recognition
                              if (isListeningNotifier.value) {
                                if (status == 200) {
                                  _startListening(displayText, modalContext);
                                } else {
                                  _startListening(
                                      "Gagal Melakukan Prediksi", modalContext);
                                }
                              } else {
                                _stopListening();
                              }
                            });
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment
                                .center, // Horizontally center the text
                            crossAxisAlignment: CrossAxisAlignment
                                .center, // Vertically center the text
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 20),
                                width: MediaQuery.of(context).orientation ==
                                        Orientation.portrait
                                    ? MediaQuery.of(context).size.width *
                                        0.6 // Height for portrait
                                    : MediaQuery.of(context).size.width *
                                        0.3, // Height for landscape
                                height: 50, // Ensure container height is set
                                decoration: BoxDecoration(
                                  color:
                                      const Color.fromARGB(255, 86, 142, 115),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ValueListenableBuilder<bool>(
                                  valueListenable: isListeningNotifier,
                                  builder: (context, isListening, child) {
                                    return Align(
                                      // Use Align to make sure the text is centered vertically
                                      alignment: Alignment
                                          .center, // Align text to the center vertically and horizontally
                                      child: Text(
                                        isListening
                                            ? "Berhenti Merekam"
                                            : "Memulai Merekam",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                        textAlign:
                                            TextAlign.center, // Center the text
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

// Function to update the dialog content without popping the bottom sheet
  void _updateImagePreviewDialog([String? kata, int? status]) {
    _speechToText.stop();
    Navigator.of(context, rootNavigator: true).pop();
    // Simply call the method again with the updated values to change the content
    _showImagePreviewDialog(kata, status);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isCameraInitialized
          ? GestureDetector(
              onTap: _takePicture,
              child: SizedBox.expand(
                child: CameraPreview(_controller!),
              ),
            )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Color.fromARGB(255, 86, 142, 115))),
                  SizedBox(height: 10),
                  Text("Menunggu Camera"),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _audioPlayer.dispose(); // Dispose the audio player when done
    super.dispose();
  }
}
