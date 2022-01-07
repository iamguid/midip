import 'dart:async';
import 'dart:io';

import 'package:dart_midi/dart_midi.dart';
import 'package:midip/src/midi_player.dart';

void main(List<String> args) {
  final file = File('./example/assets/Test.mid');
  final parser = MidiParser();
  final result = parser.parseMidiFromFile(file);
  final player = MidiPlayer();

  player.load(result);

  player.statusStream.listen((status) {
    print(status.toString());
  });

  player.play();

  Timer(const Duration(seconds: 1), () {
    player.pause();
  });

  Timer(const Duration(seconds: 2), () {
    player.play();
  });

  Timer(const Duration(seconds: 3), () {
    player.stop();
  });

  Timer(const Duration(seconds: 4), () {
    player.play();
  });
}
