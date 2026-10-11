import cv2
import mediapipe as mp

class BodyTracker:
    def __init__(self):
        self.mp_pose = mp.solutions.pose #type: ignore
        self.pose = self.mp_pose.Pose(
            static_image_mode=False,
            model_complexity=1,
            smooth_landmarks=True,
            min_detection_confidence=0.5,
            min_tracking_confidence=0.5
        )

        self.mp_drawing = mp.solutions.drawing_utils #type:ignore
        self.mp_drawing_style = mp.solutions.drawing_styles #type:ignore


    def process_frame_and_draw_skeleton(self, frame):
        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = self.pose.process(rgb_frame)

        mapped_joints = {} #Dictionary containing all joint positions mapped sent to exercise modules

        if results.pose_landmarks:
            h, w, _ = frame.shape

            #Draw skeleton on frame
            self.mp_drawing.draw_landmarks(
                frame,
                results.pose_landmarks,
                self.mp_pose.POSE_CONNECTIONS,
                landmark_drawing_spec=self.mp_drawing_style.get_default_pose_landmarks_style()

            )

            #Exctracting and building clean dictionary having joint name as key and its coordinates and visibility level as value

            for lm_id, landmark in enumerate(results.pose_landmarks.landmark):
                # 'RIGHT_SHOULDER'->'right_shoulder':{x:int, y:int, visibilty: double}
                joint_name = self.mp_pose.PoseLandmark(lm_id).name.lower()

                mapped_joints[joint_name]={
                    "x": int(landmark.x*w),
                    "y": int(landmark.y*h),
                    "visibility":round(landmark.visibility, 3)
                    }

            #Logic for custiom body points like chest
            
            if "left_shoulder" in mapped_joints and "right_shoulder" in mapped_joints:
                ls = mapped_joints["left_shoulder"]
                rs = mapped_joints["right_shoulder"]

                mapped_joints["chest"] = {
                    "x": int((ls["x"]+rs["x"])/2),
                    "y": int((ls["y"]+rs["y"])/2),
                    "visibility": round(min(ls["visibility"],rs["visibility"]), 3)
                }

            #Further logic for any other body point needed

        return frame, mapped_joints