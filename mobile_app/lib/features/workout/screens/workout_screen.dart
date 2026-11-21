import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/camera_utils.dart';
import '../../../core/utils/voice_coach.dart';
import '../../../ml/form_rules.dart';
import '../../../ml/models/exercise_spec.dart';
import '../../../ml/pose_service.dart';
import '../../../ml/rep_counter.dart';
import '../widgets/control_buttons.dart';
import '../widgets/hud_overlay.dart';
import '../widgets/movement_simulation_box.dart';
import '../widgets/skeleton_painter.dart';
import '../widgets/workout_summary_dialog.dart';

/// Focused, full-screen AI Workout Session.
/// Turns on the hardware camera ONLY during the active workout, provides
/// a 3-2-1 countdown on entry, and cleanly shuts off the camera on exit.
class WorkoutScreen extends StatefulWidget {
  final String initialExerciseKey;

  const WorkoutScreen({
    Key? key,
    this.initialExerciseKey = '1',
  }) : super(key: key);

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
  late String _selectedExerciseKey;

  bool _isCameraInitialized = false;
  bool _isProcessingFrame = false;
  bool _isSwitchingCamera = false;
  String? _errorMessage;

  // Mirror Reflection Mode
  bool _isMirrored = true;

  // Focus Mode: Minimize workout HUD & controls to see user clearly
  bool _isMinimized = false;

  // MoCap Box Maximized Mode: Expand avatar stage to center
  bool _isMocapMaximized = false;

  // Full-screen skeleton overlay (disabled by default in favor of PiP Simulation Box)
  bool _showFullScreenSkeleton = false;

  // Pre-Workout Countdown (3, 2, 1, GO!)
  int _countdownSeconds = 3;
  bool _isCountingDown = true;
  Timer? _countdownTimer;

  // Visual cues for exercise switching
  bool _showSwitchPrompt = false;
  Timer? _switchPromptTimer;

  // Toast / feedback message when toggling mirror
  String? _mirrorToast;
  Timer? _mirrorToastTimer;

  Map<String, dynamic> _currentJoints = {};
  Size _imageSize = Size.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedExerciseKey = widget.initialExerciseKey;
    _poseService = PoseService();
    _repCounter = RepCounter(exercises[_selectedExerciseKey] ?? exercises['1']!);
    _startPreWorkoutCountdown();
    _initCamera();
  }

  void _startPreWorkoutCountdown() {
    _countdownTimer?.cancel();
    _countdownSeconds = 3;
    _isCountingDown = true;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_countdownSeconds > 1) {
        HapticFeedback.selectionClick();
        setState(() => _countdownSeconds--);
      } else {
        HapticFeedback.mediumImpact();
        timer.cancel();
        setState(() {
          _isCountingDown = false;
          _showSwitchPrompt = true;
        });
        _triggerSwitchCue();
      }
    });
  }

  void _triggerSwitchCue() {
    _switchPromptTimer?.cancel();
    setState(() => _showSwitchPrompt = true);
    _switchPromptTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _showSwitchPrompt = false);
      }
    });
  }

  void _toggleMirror() {
    HapticFeedback.selectionClick();
    setState(() {
      _isMirrored = !_isMirrored;
      _mirrorToast = _isMirrored
          ? '🪞 Mirror Mode: ON (Natural Reflection)'
          : '📷 Mirror Mode: OFF (Normal Camera)';
    });

    _mirrorToastTimer?.cancel();
    _mirrorToastTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _mirrorToast = null);
      }
    });
  }

  void _toggleMocapMaximize() {
    HapticFeedback.selectionClick();
    setState(() {
      _isMocapMaximized = !_isMocapMaximized;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _switchPromptTimer?.cancel();
    _mirrorToastTimer?.cancel();

    final ctrl = _cameraController;
    _cameraController = null;
    _isCameraInitialized = false;

    _disposeController(ctrl);
    _poseService.dispose();
    super.dispose();
  }

  Future<void> _disposeController(CameraController? ctrl) async {
    if (ctrl == null) return;
    try {
      if (ctrl.value.isInitialized && ctrl.value.isStreamingImages) {
        await ctrl.stopImageStream();
      }
    } catch (_) {}
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

    _cameraController = controller;

    try {
      await controller.initialize();
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Camera initialization failed: $e');
      }
      return;
    }

    if (!mounted) {
      await controller.dispose();
      return;
    }

    setState(() {
      _isCameraInitialized = true;
      _isMirrored =
          cameraDescription.lensDirection == CameraLensDirection.front;
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
      if (!identical(ctrl, _cameraController)) return;
      if (_isProcessingFrame || _isCountingDown) return;
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
    if (!identical(capturedCtrl, _cameraController)) return;

    final inputImage = CameraUtils.inputImageFromCameraImage(
      image: image,
      camera: capturedCtrl.description,
      deviceOrientation: DeviceOrientation.portraitUp,
    );

    if (inputImage == null) return;

    final result = await _poseService.processImage(inputImage);

    if (!mounted || !identical(capturedCtrl, _cameraController)) return;

    setState(() {
      _currentJoints = result.joints;
      _imageSize = Size(image.width.toDouble(), image.height.toDouble());
      _repCounter.update(_currentJoints);

      if (_repCounter.stage == 'moving' || _repCounter.stage == 'holding') {
        _showSwitchPrompt = false;
      }
    });
  }

  void _onExerciseChanged(String key) {
    if (exercises.containsKey(key)) {
      HapticFeedback.selectionClick();
      setState(() {
        _selectedExerciseKey = key;
        _repCounter.switchExercise(exercises[key]!);
      });
      _triggerSwitchCue();
    }
  }

  void _onReset() {
    HapticFeedback.lightImpact();
    setState(() => _repCounter.reset());
  }

  void _onToggleMinimize() {
    HapticFeedback.selectionClick();
    setState(() {
      _isMinimized = !_isMinimized;
    });
  }

  void _onFinishSet() {
    final currentSpec = exercises[_selectedExerciseKey]!;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => WorkoutSummaryDialog(
        exerciseName: currentSpec.name,
        totalReps: _repCounter.reps,
        goodReps: _repCounter.goodReps,
        partialReps: _repCounter.partialReps,
        durationSeconds: _repCounter.durationSeconds,
        formScore: _repCounter.formScore,
        caloriesBurned: _repCounter.caloriesBurned,
        onSaved: () {
          setState(() {
            _repCounter.reset();
          });
        },
      ),
    );
  }

  Future<void> _onExitWorkout() async {
    if (_repCounter.reps > 0) {
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF141824),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('End Current Set?',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text(
            'You completed ${_repCounter.reps} reps of ${exercises[_selectedExerciseKey]?.name ?? 'exercise'}. Would you like to finish or discard?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, true), // Discard and exit
              child: const Text('Discard & Exit', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.pop(ctx, false);
                _onFinishSet();
              },
              child: const Text('View Summary', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (shouldExit == true && mounted) {
        Navigator.pop(context);
      }
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _onSwitchCamera() async {
    if (_isSwitchingCamera || _availableCameras.length < 2) return;

    setState(() {
      _isSwitchingCamera = true;
      _isCameraInitialized = false;
      _currentJoints = {};
      _isProcessingFrame = false;
    });

    final oldCtrl = _cameraController;
    _cameraController = null;
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Return to Home'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isCameraInitialized || _cameraController == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF00E5FF)),
              const SizedBox(height: 16),
              const Text(
                'Starting Vision Camera...',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
              ),
            ],
          ),
        ),
      );
    }

    final ctrl = _cameraController!;
    final double simBoxBottom = _isMinimized ? 65.0 : 210.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          if (_isMinimized) {
            _onToggleMinimize();
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Live camera preview with True 2D Horizontal Mirroring
            Center(
              child: Transform.scale(
                scaleX: _isMirrored ? -1.0 : 1.0,
                alignment: Alignment.center,
                child: CameraPreview(ctrl),
              ),
            ),

            // 2. Optional Full-Screen Skeleton Overlay
            if (_showFullScreenSkeleton)
              Positioned.fill(
                child: CustomPaint(
                  painter: SkeletonPainter(
                    joints: _currentJoints,
                    imageSize: _imageSize,
                    isMirrored: _isMirrored,
                  ),
                ),
              ),

            // 3. Isolated Motion Capture (MoCap) Avatar Simulation Box
            if (_isMocapMaximized)
              Positioned(
                top: 80,
                left: 16,
                right: 16,
                bottom: 85,
                child: MovementSimulationBox(
                  joints: _currentJoints,
                  imageSize: _imageSize,
                  counter: _repCounter,
                  isMirrored: _isMirrored,
                  isFullScreenSkeleton: _showFullScreenSkeleton,
                  isMaximized: true,
                  onToggleMaximize: _toggleMocapMaximize,
                  onToggleFullScreenSkeleton: () {
                    setState(() {
                      _showFullScreenSkeleton = !_showFullScreenSkeleton;
                    });
                  },
                ),
              )
            else
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                bottom: simBoxBottom,
                right: 12.0,
                width: 155,
                height: 215,
                child: MovementSimulationBox(
                  joints: _currentJoints,
                  imageSize: _imageSize,
                  counter: _repCounter,
                  isMirrored: _isMirrored,
                  isFullScreenSkeleton: _showFullScreenSkeleton,
                  isMaximized: false,
                  onToggleMaximize: _toggleMocapMaximize,
                  onToggleFullScreenSkeleton: () {
                    setState(() {
                      _showFullScreenSkeleton = !_showFullScreenSkeleton;
                    });
                  },
                ),
              ),

            // 4. Top-Left Exit Button (clean return to Dashboard)
            if (!_isMocapMaximized)
              Positioned(
                top: _isMinimized ? 55 : 55,
                left: 12,
                child: InkWell(
                  onTap: _onExitWorkout,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.70),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_ios_new, size: 12, color: Colors.white70),
                        SizedBox(width: 4),
                        Text(
                          'EXIT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 5. Floating Quick Mirror Toggle Button (Top-Right)
            if (!_isMocapMaximized)
              Positioned(
                top: _isMinimized ? 55 : 175,
                right: 12,
                child: InkWell(
                  onTap: _toggleMirror,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.70),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isMirrored
                            ? const Color(0xFF00E5FF)
                            : Colors.white24,
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isMirrored ? Icons.flip : Icons.flip_outlined,
                          size: 13,
                          color: _isMirrored
                              ? const Color(0xFF00E5FF)
                              : Colors.white60,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isMirrored ? 'MIRROR: ON' : 'MIRROR: OFF',
                          style: TextStyle(
                            color: _isMirrored
                                ? const Color(0xFF00E5FF)
                                : Colors.white60,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 6. Mirror Toast Banner Feedback
            if (_mirrorToast != null)
              Positioned(
                top: 120,
                left: 30,
                right: 30,
                child: AnimatedOpacity(
                  opacity: _mirrorToast != null ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E).withOpacity(0.95),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFF00E5FF).withOpacity(0.6)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.6),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Text(
                      _mirrorToast!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

            // 7. Telemetry HUD (Full or Minimized Pill)
            if (!_isMocapMaximized)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: HudOverlay(
                  counter: _repCounter,
                  showSwitchPrompt: _showSwitchPrompt,
                  isMinimized: _isMinimized,
                  onToggleMinimize: _onToggleMinimize,
                  onDismissSwitchPrompt: () {
                    setState(() => _showSwitchPrompt = false);
                  },
                ),
              ),

            // 8. Control Buttons Bar (Full or Minimized Capsule)
            if (!_isMocapMaximized)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ControlButtons(
                  exercises: exercises,
                  selectedKey: _selectedExerciseKey,
                  onExerciseChanged: _onExerciseChanged,
                  onReset: _onReset,
                  onFinishSet: _onFinishSet,
                  onSwitchCamera:
                      _availableCameras.length > 1 ? _onSwitchCamera : null,
                  isMinimized: _isMinimized,
                  onToggleMinimize: _onToggleMinimize,
                  isMirrored: _isMirrored,
                  onToggleMirror: _toggleMirror,
                ),
              ),

            // 9. PRE-WORKOUT COUNTDOWN OVERLAY (3, 2, 1, GO!)
            if (_isCountingDown)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.75),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          exercises[_selectedExerciseKey]?.name.toUpperCase() ??
                              'WORKOUT',
                          style: const TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFF00E5FF), width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00E5FF).withOpacity(0.35),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '$_countdownSeconds',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Step back into camera view...',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
