import cv2
from jointMapping import BodyTracker
from exercises import EXERCISES, RepCounter


def draw_hud(frame, counter):
    """Overlay exercise name, reps, angle and feedback on the frame."""
    angle_txt = f"{counter.angle:.0f} deg" if counter.angle is not None else "--"
    lines = [
        (counter.spec.name, 0.9, (255, 255, 255)),
        (f"Reps: {counter.reps}", 1.2, (0, 255, 0)),
        (f"Angle: {angle_txt}   Stage: {counter.stage}", 0.6, (255, 255, 0)),
        (counter.feedback, 0.8, (0, 200, 255)),
    ]
    y = 35
    for text, scale, color in lines:
        cv2.putText(frame, text, (15, y), cv2.FONT_HERSHEY_SIMPLEX, scale, color, 2)
        y += int(40 * scale) + 12
    cv2.putText(frame, "1: Curl  2: Squat  3: Push-up  r: reset  q: quit",
                (15, frame.shape[0] - 15), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (200, 200, 200), 1)


def start_recording():
    cap = cv2.VideoCapture(0)
    tracker = BodyTracker()
    counter = RepCounter(EXERCISES["1"])  # start with bicep curls

    while cap.isOpened():
        ret, frame = cap.read()
        # ret: checks whether webcam opened or not
        if not ret:
            break

        # mirror the frame so it behaves like a mirror for the user
        frame = cv2.flip(frame, 1)

        marked_frame, joint_data = tracker.process_frame_and_draw_skeleton(frame)

        # joint_data is empty when no person is detected; update() handles that
        counter.update(joint_data)
        draw_hud(marked_frame, counter)

        cv2.imshow("Body Tracking", marked_frame)

        key = cv2.waitKey(1) & 0xFF
        if key == ord("q"):
            break
        elif key == ord("r"):
            counter.reset()
        elif chr(key) in EXERCISES:  # switch exercise
            counter = RepCounter(EXERCISES[chr(key)])

    cap.release()
    cv2.destroyAllWindows()


if __name__ == "__main__":
    start_recording()
