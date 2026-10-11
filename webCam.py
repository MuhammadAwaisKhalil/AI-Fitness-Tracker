import cv2
from jointMapping import BodyTracker

def start_recording():
    cap = cv2.VideoCapture(0)
    tracker = BodyTracker()

    while cap.isOpened():
        ret, frame = cap.read()
        #ret: checks whether webcam opened or not
        if not ret:
            break
        #returned frame is upside down so we flip it first
        frame = cv2.flip(frame, 1)

        marked_frame, joint_data = tracker.process_frame_and_draw_skeleton(frame)

        #Just for checking data returned
        if joint_data:
            for key in ["chest", "left_shoulder", "right_shoulder"]:
                print(f"{key}: {joint_data[key]}")

        cv2.imshow('Body Tracking',marked_frame)

        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    cap.release()
    cv2.destroyAllWindows()

#for testing calling method here
start_recording()


