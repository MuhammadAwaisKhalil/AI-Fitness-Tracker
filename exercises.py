"""Exercise logic built on top of BodyTracker's joint dictionary.

BodyTracker.process_frame_and_draw_skeleton() returns:
    {"left_elbow": {"x": int, "y": int, "visibility": float}, ...}

This module turns that dictionary into joint angles, rep counts and form feedback.
Adding a new exercise = adding one ExerciseSpec at the bottom of this file.
"""
import math
from dataclasses import dataclass
from typing import Callable, Optional

MIN_VISIBILITY = 0.5  # ignore joints MediaPipe is not confident about


def calculate_angle(a, b, c):
    """Angle in degrees at joint b, formed by the segments b->a and b->c.

    a, b, c are joint dicts from jointMapping (only x and y are used).
    Returns a value between 0 and 180.
    """
    angle = abs(
        math.degrees(
            math.atan2(c["y"] - b["y"], c["x"] - b["x"])
            - math.atan2(a["y"] - b["y"], a["x"] - b["x"])
        )
    )
    return 360 - angle if angle > 180 else angle


@dataclass
class ExerciseSpec:
    name: str
    joints: tuple          # (first, middle, last) joint suffixes; the middle one is the angle vertex
    extended: float        # angle at/above this = start position (arm straight, standing, plank)
    flexed: float          # angle at/below this = full-depth rep
    partial: float         # dipping below this but not reaching `flexed` = partial rep
    partial_msg: str       # feedback for a partial rep
    form_check: Optional[Callable] = None  # (joints, side) -> warning string or None


class RepCounter:
    """Counts reps for one ExerciseSpec using a small state machine.

    waiting  -> waiting for the user to reach the start position
    extended -> in the start position
    moving   -> left the start position; tracking the deepest angle reached

    A rep is counted when the user returns to `extended` after having reached `flexed`.
    """

    def __init__(self, spec: ExerciseSpec, smoothing: float = 0.35):
        self.spec = spec
        self.alpha = smoothing  # 1.0 = no smoothing, lower = smoother but laggier
        self.reset()

    def reset(self):
        self.reps = 0
        self.stage = "waiting"
        self.angle = None
        self.feedback = "Get into the start position"
        self._min_angle = 180.0

    def _pick_side(self, joints):
        """Use whichever side of the body the camera sees best."""
        best_side, best_score = None, 0.0
        for side in ("left", "right"):
            names = [f"{side}_{j}" for j in self.spec.joints]
            if not all(n in joints for n in names):
                continue
            score = min(joints[n]["visibility"] for n in names)
            if score > best_score:
                best_side, best_score = side, score
        return best_side if best_score >= MIN_VISIBILITY else None

    def update(self, joints):
        side = self._pick_side(joints)
        if side is None:
            self.feedback = "Step back so your body is fully in view"
            return self

        a, b, c = (joints[f"{side}_{j}"] for j in self.spec.joints)
        raw = calculate_angle(a, b, c)
        self.angle = raw if self.angle is None else self.alpha * raw + (1 - self.alpha) * self.angle
        angle, spec = self.angle, self.spec

        if self.stage == "waiting":
            if angle >= spec.extended:
                self.stage, self.feedback = "extended", "Ready - start your reps"

        elif self.stage == "extended":
            if angle < spec.extended:
                self.stage = "moving"
                self._min_angle = angle

        elif self.stage == "moving":
            self._min_angle = min(self._min_angle, angle)
            if angle >= spec.extended:  # back at the start: judge the rep
                if self._min_angle <= spec.flexed:
                    self.reps += 1
                    self.feedback = "Good rep!"
                elif self._min_angle <= spec.partial:
                    self.feedback = spec.partial_msg
                self.stage = "extended"
            elif self._min_angle <= spec.flexed:
                self.feedback = "Depth reached - now return"

        if spec.form_check:
            warning = spec.form_check(joints, side)
            if warning:
                self.feedback = warning
        return self


# ---------------------------------------------------------------- form checks
def _pushup_form(joints, side):
    """Shoulder-hip-ankle should be roughly a straight line (side-on camera)."""
    names = [f"{side}_{j}" for j in ("shoulder", "hip", "ankle")]
    if not all(n in joints and joints[n]["visibility"] >= MIN_VISIBILITY for n in names):
        return None
    if calculate_angle(*(joints[n] for n in names)) < 155:
        return "Keep your hips in line with your shoulders"
    return None


def _squat_form(joints, side):
    """Check torso collapse forward."""
    names = [f"{side}_{j}" for j in ("shoulder", "hip", "knee")]
    if not all(n in joints and joints[n]["visibility"] >= MIN_VISIBILITY for n in names):
        return None
    if calculate_angle(*(joints[n] for n in names)) < 65:
        return "Keep your chest lifted - don't collapse"
    return None


def _plank_form(joints, side):
    """Ensure flat back plank."""
    names = [f"{side}_{j}" for j in ("shoulder", "hip", "ankle")]
    if not all(n in joints and joints[n]["visibility"] >= MIN_VISIBILITY for n in names):
        return None
    angle = calculate_angle(*(joints[n] for n in names))
    if angle < 150:
        return "Hips sagging! Tighten core"
    elif angle > 195:
        return "Hips too high! Lower hips level with spine"
    return None


# ---------------------------------------------------------------- exercise library
BICEP_CURL = ExerciseSpec(
    name="Bicep Curl",
    joints=("shoulder", "elbow", "wrist"),
    extended=150, flexed=50, partial=100,
    partial_msg="Curl all the way up",
)

SQUAT = ExerciseSpec(
    name="Squat",
    joints=("hip", "knee", "ankle"),
    extended=160, flexed=100, partial=130,
    partial_msg="Go deeper - hips down",
    form_check=_squat_form,
)

PUSH_UP = ExerciseSpec(
    name="Push-Up",
    joints=("shoulder", "elbow", "wrist"),
    extended=155, flexed=90, partial=120,
    partial_msg="Lower your chest further",
    form_check=_pushup_form,
)

SHOULDER_PRESS = ExerciseSpec(
    name="Shoulder Press",
    joints=("shoulder", "elbow", "wrist"),
    extended=160, flexed=85, partial=125,
    partial_msg="Press fully overhead",
)

LUNGE = ExerciseSpec(
    name="Lunge",
    joints=("hip", "knee", "ankle"),
    extended=160, flexed=95, partial=125,
    partial_msg="Lower hips deeper into lunge",
)

PLANK = ExerciseSpec(
    name="Plank",
    joints=("shoulder", "hip", "ankle"),
    extended=160, flexed=160, partial=145,
    partial_msg="Keep body in a straight plank line",
    form_check=_plank_form,
)

JUMPING_JACKS = ExerciseSpec(
    name="Jumping Jacks",
    joints=("hip", "shoulder", "wrist"),
    extended=40, flexed=140, partial=90,
    partial_msg="Clap hands overhead",
)

HIGH_KNEES = ExerciseSpec(
    name="High Knees",
    joints=("shoulder", "hip", "knee"),
    extended=160, flexed=85, partial=120,
    partial_msg="Drive knee up to hip level",
)

# Key pressed in webCam.py -> exercise
EXERCISES = {
    "1": BICEP_CURL,
    "2": PUSH_UP,
    "3": SHOULDER_PRESS,
    "4": SQUAT,
    "5": LUNGE,
    "6": PLANK,
    "7": JUMPING_JACKS,
    "8": HIGH_KNEES,
}

