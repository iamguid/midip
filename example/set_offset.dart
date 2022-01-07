import 'dart:io';

import 'package:dart_midi/dart_midi.dart';
import 'package:midip/src/midi_player.dart';

void main(List<String> args) {
  final file = File('./example/assets/Test.mid');
  final parser = MidiParser();
  final result = parser.parseMidiFromFile(file);
  final player = MidiPlayer();

  player.load(result);

  player.timeOffsetMs = -3000;

  player.midiEventsStream.listen((event) {
    if (event is NoteOnEvent) {
      print('ON:  ${event.noteNumber}');
    }
    if (event is NoteOffEvent) {
      print('OFF: ${event.noteNumber}');
    }
  });

  player.play();
}
