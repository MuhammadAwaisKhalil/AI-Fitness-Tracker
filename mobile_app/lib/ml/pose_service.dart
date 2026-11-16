import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Result container holding the mapped joint dictionary compatible with Python
/// and the raw ML Kit poses.
class PoseResult {
  /// Joint dictionary in the exact format used by Python jointMapping.py:
  /// {"left_shoulder": {"x": 10, "y": 20, "visibility": 0.9}, ..., "chest": {...}}
  final Map<String, dynamic> joints;

  /// Raw poses detected by ML Kit.
  final List<Pose> poses;

  const PoseResult({
    required this.joints,
    required this.poses,
  });

  bool get hasPose => poses.isNotEmpty && joints.isNotEmpty;
}

/// Wrapper for [PoseDetector] from `google_mlkit_pose_detection`.
/// Converts ML Kit pose output into the exact joint dictionary format
/// established in Python `jointMapping.py`.
class PoseService {
  final PoseDetector _poseDetector;

  PoseService({PoseDetectorOptions? options})
      : _poseDetector = PoseDetector(
          options: options ??
              PoseDetectorOptions(
                mode: PoseDetectionMode.stream,
                model: PoseDetectionModel.base,
              ),
        );

  /// Mapping from ML Kit PoseLandmarkType to lower snake_case landmark names
  /// matching MediaPipe Python PoseLandmark enum strings.
  static const Map<PoseLandmarkType, String> _landmarkMapping = {
    PoseLandmarkType.nose: 'nose',
    PoseLandmarkType.leftEyeInner: 'left_eye_inner',
    PoseLandmarkType.leftEye: 'left_eye',
    PoseLandmarkType.leftEyeOuter: 'left_eye_outer',
    PoseLandmarkType.rightEyeInner: 'right_eye_inner',
    PoseLandmarkType.rightEye: 'right_eye',
    PoseLandmarkType.rightEyeOuter: 'right_eye_outer',
    PoseLandmarkType.leftEar: 'left_ear',
    PoseLandmarkType.rightEar: 'right_ear',
    PoseLandmarkType.leftMouth: 'mouth_left',
    PoseLandmarkType.rightMouth: 'mouth_right',
    PoseLandmarkType.leftShoulder: 'left_shoulder',
    PoseLandmarkType.rightShoulder: 'right_shoulder',
    PoseLandmarkType.leftElbow: 'left_elbow',
    PoseLandmarkType.rightElbow: 'right_elbow',
    PoseLandmarkType.leftWrist: 'left_wrist',
    PoseLandmarkType.rightWrist: 'right_wrist',
    PoseLandmarkType.leftPinky: 'left_pinky',
    PoseLandmarkType.rightPinky: 'right_pinky',
    PoseLandmarkType.leftIndex: 'left_index',
    PoseLandmarkType.rightIndex: 'right_index',
    PoseLandmarkType.leftThumb: 'left_thumb',
    PoseLandmarkType.rightThumb: 'right_thumb',
    PoseLandmarkType.leftHip: 'left_hip',
    PoseLandmarkType.rightHip: 'right_hip',
    PoseLandmarkType.leftKnee: 'left_knee',
    PoseLandmarkType.rightKnee: 'right_knee',
    PoseLandmarkType.leftAnkle: 'left_ankle',
    PoseLandmarkType.rightAnkle: 'right_ankle',
    PoseLandmarkType.leftHeel: 'left_heel',
    PoseLandmarkType.rightHeel: 'right_heel',
    PoseLandmarkType.leftFootIndex: 'left_foot_index',
    PoseLandmarkType.rightFootIndex: 'right_foot_index',
  };

  /// Processes an [InputImage] from the camera stream, detects human poses,
  /// maps them into the joint dictionary format, and computes custom joints like "chest".
  Future<PoseResult> processImage(InputImage inputImage) async {
    final List<Pose> poses = await _poseDetector.processImage(inputImage);
    final Map<String, dynamic> mappedJoints = {};

    if (poses.isNotEmpty) {
      // Use the primary detected person (first pose)
      final pose = poses.first;

      for (final entry in pose.landmarks.entries) {
        final landmarkType = entry.key;
        final landmark = entry.value;
        final jointName = _landmarkMapping[landmarkType];

        if (jointName != null) {
          mappedJoints[jointName] = {
            'x': landmark.x.toInt(),
            'y': landmark.y.toInt(),
            'visibility': double.parse(landmark.likelihood.toStringAsFixed(3)),
          };
        }
      }

      // Replicate custom logic for "chest" from jointMapping.py:
      // Midpoint between left_shoulder and right_shoulder with minimum visibility.
      if (mappedJoints.containsKey('left_shoulder') &&
          mappedJoints.containsKey('right_shoulder')) {
        final ls = mappedJoints['left_shoulder'] as Map<String, dynamic>;
        final rs = mappedJoints['right_shoulder'] as Map<String, dynamic>;

        final int lsX = (ls['x'] as num).toInt();
        final int lsY = (ls['y'] as num).toInt();
        final double lsVis = (ls['visibility'] as num).toDouble();

        final int rsX = (rs['x'] as num).toInt();
        final int rsY = (rs['y'] as num).toInt();
        final double rsVis = (rs['visibility'] as num).toDouble();

        final double chestVis = math.min(lsVis, rsVis);

        mappedJoints['chest'] = {
          'x': ((lsX + rsX) / 2).toInt(),
          'y': ((lsY + rsY) / 2).toInt(),
          'visibility': double.parse(chestVis.toStringAsFixed(3)),
        };
      }
    }

    return PoseResult(joints: mappedJoints, poses: poses);
  }

  /// Convenience method that returns only the joint dictionary.
  Future<Map<String, dynamic>> processImageToJoints(InputImage inputImage) async {
    final result = await processImage(inputImage);
    return result.joints;
  }

  /// Releases resources held by the underlying ML Kit detector.
  Future<void> dispose() async {
    await _poseDetector.close();
  }
}

