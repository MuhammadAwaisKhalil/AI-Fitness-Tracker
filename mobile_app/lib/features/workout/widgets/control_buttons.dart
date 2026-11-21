import 'package:flutter/material.dart';
import '../../../ml/models/exercise_spec.dart';
import '../../../core/utils/voice_coach.dart';

/// Interactive workout control panel featuring Category filters (Cardio, Strength, Legs, Core),
/// categorized exercise selection carousel, and workout management actions.
/// Fully responsive with zero pixel overflow on any screen size.
class ControlButtons extends StatefulWidget {
  final Map<String, ExerciseSpec> exercises;
  final String selectedKey;
  final ValueChanged<String> onExerciseChanged;
  final VoidCallback onReset;
  final VoidCallback onFinishSet;
  final VoidCallback? onSwitchCamera;
  final bool isMinimized;
  final VoidCallback onToggleMinimize;
  final bool isMirrored;
  final VoidCallback onToggleMirror;

  const ControlButtons({
    Key? key,
    required this.exercises,
    required this.selectedKey,
    required this.onExerciseChanged,
    required this.onReset,
    required this.onFinishSet,
    this.onSwitchCamera,
    this.isMinimized = false,
    required this.onToggleMinimize,
    this.isMirrored = true,
    required this.onToggleMirror,
  }) : super(key: key);

  @override
  State<ControlButtons> createState() => _ControlButtonsState();
}

class _ControlButtonsState extends State<ControlButtons> {
  late ExerciseCategory _selectedCategory;

  @override
  void initState() {
    super.initState();
    final currentSpec = widget.exercises[widget.selectedKey];
    _selectedCategory = currentSpec?.category ?? ExerciseCategory.strength;
  }

  @override
  void didUpdateWidget(covariant ControlButtons oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedKey != widget.selectedKey) {
      final currentSpec = widget.exercises[widget.selectedKey];
      if (currentSpec != null && currentSpec.category != _selectedCategory) {
        setState(() {
          _selectedCategory = currentSpec.category;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ----------------------------------------------------
    // 1. MINIMIZED FOCUS BAR (Safe, Overflow-Proof)
    // ----------------------------------------------------
    if (widget.isMinimized) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.80),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: widget.onFinishSet,
                    child: const Text(
                      'FINISH SET',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _compactIconButton(
                    icon: widget.isMirrored ? Icons.flip : Icons.flip_outlined,
                    color: widget.isMirrored
                        ? const Color(0xFF00E5FF)
                        : Colors.white60,
                    tooltip: 'Toggle Mirror Reflection',
                    onPressed: widget.onToggleMirror,
                  ),
                  _compactIconButton(
                    icon: VoiceCoach.instance.isMuted
                        ? Icons.volume_off
                        : Icons.volume_up,
                    color: VoiceCoach.instance.isMuted
                        ? Colors.white38
                        : const Color(0xFF76FF03),
                    tooltip: 'Mute / Audio',
                    onPressed: () {
                      setState(() {
                        VoiceCoach.instance.toggleMute();
                      });
                    },
                  ),
                  if (widget.onSwitchCamera != null)
                    _compactIconButton(
                      icon: Icons.flip_camera_ios,
                      color: Colors.white70,
                      tooltip: 'Flip Camera',
                      onPressed: widget.onSwitchCamera!,
                    ),
                  _compactIconButton(
                    icon: Icons.expand_less,
                    color: const Color(0xFF00E5FF),
                    tooltip: 'Expand Controls',
                    onPressed: widget.onToggleMinimize,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ----------------------------------------------------
    // 2. EXPANDED FULL CONTROLS BAR (Zero Overflow)
    // ----------------------------------------------------
    final categoryExercises = widget.exercises.entries
        .where((e) => e.value.category == _selectedCategory)
        .toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            borderRadius: BorderRadius.circular(22.0),
            border: Border.all(color: Colors.white12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. CATEGORY SELECTOR TABS (Strength, Legs, Cardio, Core)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: ExerciseCategory.values.map((cat) {
                    final isSelected = cat == _selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat;
                          });
                          final inCat = widget.exercises.entries
                              .where((e) => e.value.category == cat)
                              .toList();
                          if (inCat.isNotEmpty &&
                              widget.exercises[widget.selectedKey]?.category !=
                                  cat) {
                            widget.onExerciseChanged(inCat.first.key);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 11.0, vertical: 5.0),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? cat.color.withOpacity(0.2)
                                : Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(14.0),
                            border: Border.all(
                              color:
                                  isSelected ? cat.color : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                cat.icon,
                                size: 13,
                                color: isSelected ? cat.color : Colors.white60,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                cat.label,
                                style: TextStyle(
                                  color:
                                      isSelected ? cat.color : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 8),

              // 2. EXERCISE CAROUSEL FOR SELECTED CATEGORY
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categoryExercises.map((entry) {
                    final isSelected = entry.key == widget.selectedKey;
                    final spec = entry.value;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3.0),
                      child: InkWell(
                        onTap: () => widget.onExerciseChanged(entry.key),
                        borderRadius: BorderRadius.circular(12.0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10.0, vertical: 6.0),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _selectedCategory.color.withOpacity(0.25)
                                : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              color: isSelected
                                  ? _selectedCategory.color
                                  : Colors.white10,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                spec.name,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.0,
                                ),
                              ),
                              Text(
                                spec.targetMuscle,
                                style: TextStyle(
                                  color: isSelected
                                      ? _selectedCategory.color
                                      : Colors.white38,
                                  fontSize: 9.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 10),

              // 3. ACTION CONTROLS ROW (Guaranteed Zero Horizontal Overflow)
              Row(
                children: [
                  // FINISH SET BUTTON (Main CTA)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.onFinishSet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E5FF),
                        foregroundColor: Colors.black,
                        elevation: 3,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.flag_circle, size: 16),
                          SizedBox(width: 5),
                          Text(
                            'FINISH SET',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  // RESET BUTTON (Compact Icon with Tooltip)
                  _compactIconButton(
                    icon: Icons.refresh,
                    color: Colors.white70,
                    tooltip: 'Reset Count',
                    onPressed: widget.onReset,
                  ),

                  // MIRROR TOGGLE
                  _compactIconButton(
                    icon: widget.isMirrored ? Icons.flip : Icons.flip_outlined,
                    color: widget.isMirrored
                        ? const Color(0xFF00E5FF)
                        : Colors.white38,
                    tooltip: 'Toggle Mirror',
                    onPressed: widget.onToggleMirror,
                  ),

                  // AUDIO TOGGLE
                  _compactIconButton(
                    icon: VoiceCoach.instance.isMuted
                        ? Icons.volume_off
                        : Icons.volume_up,
                    color: VoiceCoach.instance.isMuted
                        ? Colors.white38
                        : const Color(0xFF76FF03),
                    tooltip: 'Voice / Audio Cues',
                    onPressed: () {
                      setState(() {
                        VoiceCoach.instance.toggleMute();
                      });
                    },
                  ),

                  // SWITCH CAMERA
                  if (widget.onSwitchCamera != null)
                    _compactIconButton(
                      icon: Icons.flip_camera_ios,
                      color: Colors.white70,
                      tooltip: 'Flip Camera',
                      onPressed: widget.onSwitchCamera!,
                    ),

                  // MINIMIZE / FOCUS MODE
                  _compactIconButton(
                    icon: Icons.fullscreen,
                    color: const Color(0xFF00E5FF),
                    tooltip: 'Focus Mode (Minimize)',
                    onPressed: widget.onToggleMinimize,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _compactIconButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2.0),
      child: Material(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPressed,
          child: Tooltip(
            message: tooltip,
            child: Container(
              width: 35,
              height: 35,
              alignment: Alignment.center,
              child: Icon(icon, color: color, size: 18),
            ),
          ),
        ),
      ),
    );
  }
}
