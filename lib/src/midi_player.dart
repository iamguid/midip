import 'dart:async';

import 'package:dart_midi/dart_midi.dart';
import 'package:midip/src/track_player.dart';

enum MidiPlayerStatus { play, stop, pause, end }

class MidiPlayer {
  MidiPlayer() {
    midiEventsStream = _midiEventsSC.stream;
    statusStream = _statusEventsSC.stream;
  }

  /// Sample rate in milliseconds that used by default
  /// That sample rate based on "average" ppq (96) and "average" bpm (120)
  /// 60 / 120 = 0.5 seconds per beat
  /// 500ms / 96 = 5.208333ms per clock tick.
  static const _sampleRateMs = 5;

  /// Default tempo in bpm that used until set tempo midi event
  static const _defaultTempoBpm = 120;

  /// Current tempo in bpm that used until set tempo midi event or setTempo
  int _currentTempoBpm = MidiPlayer._defaultTempoBpm;

  /// Indicates is player in playing state or not
  bool _isPlaying = false;
  get isPlaying => _isPlaying;

  /// Indicates is player in paused state or not
  bool _isPaused = false;
  get isPaused => _isPaused;

  /// Indicates is player in stopped state or not
  bool _isStopped = true;
  get isStopped => _isStopped;

  /// Stream controller where put playable midi events
  final StreamController<MidiEvent> _midiEventsSC =
      StreamController.broadcast();

  late Stream<MidiEvent> midiEventsStream;

  /// Stream controller where put play status
  final StreamController<MidiPlayerStatus> _statusEventsSC =
      StreamController.broadcast();

  late Stream<MidiPlayerStatus> statusStream;

  /// Loaded midi file
  MidiFile? _file;

  /// Prepared track players
  final List<TrackPlayer> _tracks = [];

  /// Timer that counts track time from beginning to end
  Stopwatch? _playbackTimer;

  /// Offset that used for in fly bpm change
  int _timeOffsetMs = 0;

  /// Periodic timer that calls [_playLoop] once at [_sampleRateMs]
  Timer? _loopTimer;

  /// Count all events
  int _processedEventsCount = 0;

  /// Returns current time of track in milliseconds
  int get currentTimeMs {
    if (_playbackTimer == null) {
      return 0;
    }

    return _playbackTimer!.elapsed.inMilliseconds + _timeOffsetMs;
  }

  set tempo(int tempo) {
    final currentMillisecondsPerTick = _millisecondsPerTick;
    final currentTicks = currentTimeMs / currentMillisecondsPerTick;
    final currentTicksMs = currentTicks * currentMillisecondsPerTick;

    _currentTempoBpm = tempo;

    final newMillisecondsPerTicks = _millisecondsPerTick;
    final newTicks = currentTimeMs / newMillisecondsPerTicks;
    final newTicksMs = newTicks * currentMillisecondsPerTick;

    _timeOffsetMs = (newTicksMs - currentTicksMs).floor();
  }

  /// The main loop that calls each [_currentSampleRateMs]
  void _playLoop(Timer _) {
    for (var track in _tracks) {
      while (true) {
        final upcomingEvent =
            track.nextUpcomingEvent(currentTimeMs, _millisecondsPerTick);

        if (upcomingEvent == null) {
          break;
        }

        final midiEvent = upcomingEvent.midiEvent;

        if (midiEvent is SetTempoEvent) {
          _currentTempoBpm = midiEvent.microsecondsPerBeat;
        }

        _midiEventsSC.add(midiEvent);

        _processedEventsCount++;
      }
    }

    if (_processedEventsCount >= getTotalEvents()) {
      stop();
      _statusEventsSC.add(MidiPlayerStatus.end);
    }
  }

  num get _millisecondsPerTick {
    if (_file!.header.ticksPerBeat != null) {
      return 60000 / (_file!.header.ticksPerBeat! * _currentTempoBpm);
    } else {
      return 60000 /
          (_file!.header.framesPerSecond *
              _file!.header.ticksPerFrame *
              _currentTempoBpm);
    }
  }

  /// Loads `dart_midi` MidiFile
  void load(MidiFile file) {
    _file = file;

    for (var events in file.tracks) {
      _tracks.add(TrackPlayer(events));
    }
  }

  /// Pause midi player
  void pause() {
    if (!isPlaying || isPaused) return;

    // Stop timer
    _playbackTimer!.stop();

    // Stop looping
    _loopTimer!.cancel();

    _isPlaying = false;
    _isPaused = true;
    _isStopped = false;

    _statusEventsSC.add(MidiPlayerStatus.pause);
  }

  /// Stop midi player and reset state
  void stop() {
    if (!isPlaying || isStopped) return;

    // Reset events counter
    _processedEventsCount = 0;

    // Stop and reset timer
    _playbackTimer!
      ..stop()
      ..reset();

    // Stop looping
    _loopTimer!.cancel();

    _isPlaying = false;
    _isPaused = false;
    _isStopped = true;

    _statusEventsSC.add(MidiPlayerStatus.stop);
  }

  /// Start playing from begin
  void play() {
    if (isPlaying) return;

    if (!isPaused) {
      _playbackTimer ??= Stopwatch();
    }

    _playbackTimer!.start();

    // Start loop
    _loopTimer =
        Timer.periodic(const Duration(milliseconds: _sampleRateMs), _playLoop);

    _isPlaying = true;
    _isPaused = false;
    _isStopped = false;

    _statusEventsSC.add(MidiPlayerStatus.play);
  }

  /// Gets total number of events in the loaded MIDI file.
  getTotalEvents() {
    return _tracks.fold<int>(0,
        (previousValue, element) => previousValue + element.midiEvents.length);
  }
}
