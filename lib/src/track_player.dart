import 'package:dart_midi/dart_midi.dart';

class TrackPlayerEvent {
  final int tick;
  final int timeMs;
  final MidiEvent midiEvent;

  TrackPlayerEvent({
    required this.timeMs,
    required this.tick,
    required this.midiEvent,
  });
}

class TrackPlayer {
  final List<MidiEvent> midiEvents;

  TrackPlayer(this.midiEvents);

  int _currentEventIndex = 0;
  int _currentEventTick = 0;

  TrackPlayerEvent? nextUpcomingEvent(
      int currentTimeMs, num tickToMsMultiplier) {
    if (_currentEventIndex >= midiEvents.length) {
      return null;
    }

    final currentEventTimeMs = (_currentEventTick * tickToMsMultiplier).floor();

    if (currentEventTimeMs > currentTimeMs) {
      return null;
    }

    final currentEvent = midiEvents[_currentEventIndex];

    final currentTrackPlayerEvent = TrackPlayerEvent(
      timeMs: currentEventTimeMs,
      tick: _currentEventTick,
      midiEvent: currentEvent,
    );

    _currentEventTick += currentEvent.deltaTime;
    _currentEventIndex++;

    return currentTrackPlayerEvent;
  }
}
