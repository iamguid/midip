import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dart_midi/dart_midi.dart';
import 'package:midip/src/midi_player.dart';

void main(List<String> args) {
  final file = File('./lib/example/assets/Test.mid');
  final parser = MidiParser();
  final result = parser.parseMidiFromFile(file);
  final player = MidiPlayer();

  player.load(result);

  player.midiEventsStream.listen((event) {
    if (event is NoteOnEvent) {
      print('NOTE: ${event.noteNumber}');
    }
  });

  Timer.periodic(const Duration(milliseconds: 1000), (Timer _) {
    final sinBpm = sin(pi / (DateTime.now().microsecond)) * 10000;
    player.tempo = sinBpm.floor();
    print('BPM: $sinBpm');
  });

  player.play();
}
