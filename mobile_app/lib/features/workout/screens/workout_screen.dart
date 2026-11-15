import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/camera_utils.dart';
import '../../../ml/form_rules.dart';
import '../../../ml/pose_service.dart';
import '../../../ml/rep_counter.dart';
import '../widgets/control_buttons.dart';
import '../widgets/hud_overlay.dart';
import '../widgets/skeleton_painter.dart';

/// Workout screen providing real-time camera stream, pose estimation,
/// rep counting state machine, skeleton rendering, and interactive controls.
/// Pure Flutter translation of `webCam.py`.
class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({Key? key}) : super(key: key);

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _availableCameras = [];
  int _cameraIndex = 0;

  late PoseService _poseService;
  late RepCounter _repCounter;
  String _selectedExerciseKey = '1';

  bool _isCameraInitialized = false;
  bool _isProcessingFrame = false;
  bool _isSwitchingCamera = false; // Guard against overlapping switch calls
  String? _errorMessage;

  Map<String, dynamic> _currentJoints = {};
  Size _imageSize = Size.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _poseService = PoseService();
    _repCounter = RepCounter(exercises[_selectedExerciseKey]!);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Synchronously null the controller reference FIRST so any in-flight
    // image-stream callbacks bail out immediately on the null check.
    final ctrl = _cameraController;
    _cameraController = null;
    _isCameraInitialized = false;

    // Best-effort async cleanup – fire and forget is acceptable in dispose().
    _disposeController(ctrl);
    _poseService.dispose();
    super.dispose();
  }

  /// Safely stops the stream, then disposes a given controller.
  /// Accepts the controller as a parameter so it can be used both in
  /// dispose() and during camera switching.
  Future<void> _disposeController(CameraController? ctrl) async {
    if (ctrl == null) return;
    try {
      if (ctrl.value.isInitialized && ctrl.value.isStreamingImages) {
        await ctrl.stopImageStream();
      }
    } catch (_) {
      // Ignore errors from already-disposed controller
    }
    try {
      await ctrl.dispose();
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _cameraController;
    if (ctrl == null || !ctrl.value.isInitialized) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      // Stop streaming when the app goes to background
      if (ctrl.value.isStreamingImages) {
        ctrl.stopImageStream().catchError((_) {});
      }
    } else if (state == AppLifecycleState.resumed) {
      _startCameraStream();
    }
  }

  Future<void> _initCamera() async {
    try {
      _availableCameras = await availableCameras();
      if (_availableCameras.isEmpty) {
        if (mounted) {
          setState(() => _errorMessage = 'No camera found on this device.');
        }
        return;
      }

      // Default to front camera for mirror experience
      final frontIndex = _availableCameras.indexWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
      );
      _cameraIndex = frontIndex != -1 ? frontIndex : 0;

      await _setupCameraController(_availableCameras[_cameraIndex]);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Failed to initialize camera: $e');
      }
    }
  }

  Future<void> _setupCameraController(
      CameraDescription cameraDescription) async {
    final controller = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    // Assign immediately so dispose() can clean it up if the widget is
    // removed before initialization completes.
    _cameraController = controller;

    try {
      await controller.initialize();
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Camera initialization failed: $e');
      }
      return;
    }

    // Widget may have been disposed while we awaited initialize().
    if (!mounted) {
      await controller.dispose();
      return;
    }

    setState(() {
      _isCameraInitialized = true;
    });

    _startCameraStream();
  }

  void _startCameraStream() {
    final ctrl = _cameraController;
    if (ctrl == null ||
        !ctrl.value.isInitialized ||
        ctrl.value.isStreamingImages) {
      return;
    }

    ctrl.startImageStream((CameraImage image) {
      // Bail out if the controller was replaced (camera switch) or disposed.
      if (!identical(ctrl, _cameraController)) return;
      if (_isProcessingFrame) return;
      _isProcessingFrame = true;

      _processCameraImage(image, ctrl).then((_) {
        _isProcessingFrame = false;
      }).catchError((_) {
        _isProcessingFrame = false;
      });
    });
  }

  Future<void> _processCameraImage(
      CameraImage image, CameraController capturedCtrl) async {
    // Bail if the controller has been swapped since this frame was captured.
    if (!identical(capturedCtrl, _cameraController)) return;

    final inputImage = CameraUtils.inputImageFromCameraImage(
      image: image,
      camera: capturedCtrl.description,
      deviceOrientation: DeviceOrientation.portraitUp,
    );

    if (inputImage == null) return;

    final result = await _poseService.processImage(inputImage);

    // Double-check after the async gap: widget may have been disposed or
    // the camera may have been switched in the meantime.
    if (!mounted || !identical(capturedCtrl, _cameraController)) return;

    setState(() {
      _currentJoints = result.joints;
      _imageSize = Size(image.width.toDouble(), image.height.toDouble());
      _repCounter.update(_currentJoints);
    });
  }

  void _onExerciseChanged(String key) {
    if (exercises.containsKey(key)) {
      setState(() {
        _selectedExerciseKey = key;
        _repCounter.switchExercise(exercises[key]!);
      });
    }
  }

  void _onReset() {
    setState(() => _repCounter.reset());
  }

  Future<void> _onSwitchCamera() async {
    // Prevent double-tapping from triggering overlapping switches.
    if (_isSwitchingCamera || _availableCameras.length < 2) return;

    setState(() {
      _isSwitchingCamera = true;
      _isCameraInitialized = false; // Show spinner during transition
      _currentJoints = {};         // Clear stale skeleton
      _isProcessingFrame = false;  // Unlock pipeline
    });

    // Capture the old controller and immediately null the shared reference
    // so any in-flight stream callbacks see null and bail out.
    final oldCtrl = _cameraController;
    _cameraController = null;

    // Dispose the old controller (stops stream + disposes safely).
    await _disposeController(oldCtrl);

    _cameraIndex = (_cameraIndex + 1) % _availableCameras.length;

    if (!mounted) return;

    await _setupCameraController(_availableCameras[_cameraIndex]);

    if (mounted) {
      setState(() => _isSwitchingCamera = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent, fontSize: 16),
            ),
          ),
        ),
      );
    }

    if (!_isCameraInitialized || _cameraController == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
        ),
      );
    }

    final ctrl = _cameraController!;
    final isFrontCamera =
        ctrl.description.lensDirection == CameraLensDirection.front;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera live preview (mirrored for front camera)
          Center(
            child: isFrontCamera
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(math.pi),
                    child: CameraPreview(ctrl),
                  )
                : CameraPreview(ctrl),
          ),

          // 2. Pose skeleton overlay
          Positioned.fill(
            child: CustomPaint(
              painter: SkeletonPainter(
                joints: _currentJoints,
                imageSize: _imageSize,
                isFrontCamera: isFrontCamera,
              ),
            ),
          ),

          // 3. Telemetry HUD
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HudOverlay(counter: _repCounter),
          ),

          // 4. Exercise controls and camera switch
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ControlButtons(
              exercises: exercises,
              selectedKey: _selectedExerciseKey,
              onExerciseChanged: _onExerciseChanged,
              onReset: _onReset,
              onSwitchCamera:
                  _availableCameras.length > 1 ? _onSwitchCamera : null,
            ),
          ),
        ],
      ),
    );
  }
}

