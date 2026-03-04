import 'package:flutter_riverpod/flutter_riverpod.dart';

class MotionSeenController extends StateNotifier<Set<String>> {
  MotionSeenController() : super(const <String>{});

  void markSeen(String key) {
    if (state.contains(key)) {
      return;
    }
    state = <String>{...state, key};
  }

  void clear() {
    state = const <String>{};
  }
}

final motionSeenProvider =
    StateNotifierProvider<MotionSeenController, Set<String>>((ref) {
  return MotionSeenController();
});
