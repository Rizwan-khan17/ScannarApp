import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// A stateful widget responsible for managing the device camera hardware,
/// initializing controllers, handling UI states, and capturing document images.
class CameraScannerScreen extends StatefulWidget {
  const CameraScannerScreen({super.key});

  @override
  State<CameraScannerScreen> createState() => _CameraScannerScreenState();
}

class _CameraScannerScreenState extends State<CameraScannerScreen> {
  // Controller required to interact with and control the device camera hardware.
  CameraController? _controller;

  // State flags to manage UI feedback during loading, capturing, or error handling.
  bool _isInitializing = true;
  bool _isCapturing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Kick off camera initialization as soon as this screen enters the widget tree.
    _initializeCamera();
  }

  /// Asynchronously fetches available cameras, selects the back camera,
  /// and initializes the CameraController.
  Future<void> _initializeCamera() async {
    try {
      // Retrieve all available physical cameras on the device.
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        throw Exception('No camera found on this device.');
      }

      // Find the back-facing camera; fallback to the first available camera if not found.
      final backCamera = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      // Instantiate the controller with high resolution and audio disabled (since we only scan documents).
      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      // Initialize the controller (asynchronous operation establishing camera streams).
      await controller.initialize();

      // Ensure the widget is still active in the widget tree before calling setState.
      if (!mounted) {
        await controller.dispose();
        return;
      }

      // Update state to indicate initialization is complete and store the active controller.
      setState(() {
        _controller = controller;
        _isInitializing = false;
      });
    } catch (e) {
      if (!mounted) return;

      // Handle any hardware errors or missing permissions gracefully.
      setState(() {
        _error = e.toString();
        _isInitializing = false;
      });
    }
  }

  /// Captures an image from the live camera feed and saves it to app-private storage.
  Future<void> _captureDocument() async {
    final controller = _controller;

    // Guard clause: Ensure controller is active and ready, and we aren't already capturing.
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      // Take a picture and get a temporary XFile object.
      final photo = await controller.takePicture();

      // Retrieve the application's document directory for secure, permanent local storage.
      final directory = await getApplicationDocumentsDirectory();

      // Construct a unique file path using a timestamp.
      final savedPath = '${directory.path}/scan_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Copy the temporary captured photo into app-private permanent storage.
      final savedFile = await File(photo.path).copy(savedPath);

      if (!mounted) return;

      // Navigate to the preview screen, passing the saved image file path.
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScannedImagePreview(
            imagePath: savedFile.path,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Show a snackbar if the capture process encounters an error.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Capture failed: $e')),
      );
    } finally {
      // Reset capturing flag once process finishes (success or failure).
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Crucial: Always dispose of the camera controller to free up native system resources and prevent memory leaks.
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Document Scanner'),
        centerTitle: true,
      ),
      // Conditional rendering based on initialization or error state.
      body: _isInitializing
          ? const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      )
          : _error != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      )
          : Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Place the document inside the frame',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
          // Live camera preview area with an overlay guide.
          Expanded(
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (controller != null)
                    Center(
                      child: AspectRatio(
                        aspectRatio: controller.value.aspectRatio,
                        child: CameraPreview(controller),
                      ),
                    ),

                  // Visual alignment frame guide (preparatory for border detection feature).
                  Center(
                    child: FractionallySizedBox(
                      widthFactor: 0.82,
                      heightFactor: 0.62,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.greenAccent,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Capture shutter button at the bottom.
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 28,
            ),
            child: GestureDetector(
              onTap: _isCapturing ? null : _captureDocument,
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 5,
                  ),
                ),
                child: _isCapturing
                    ? const Padding(
                  padding: EdgeInsets.all(18),
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                )
                    : const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A stateless preview screen that displays the captured document image from local storage.
class ScannedImagePreview extends StatelessWidget {
  final String imagePath;

  const ScannedImagePreview({
    super.key,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Captured Document'),
      ),
      body: Center(
        // Load and display the image directly from the saved file path using Image.file.
        child: Image.file(
          File(imagePath),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}