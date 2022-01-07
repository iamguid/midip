import 'dart:io';

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
      print(event.noteNumber);
    }
  });

  player.play();
}
