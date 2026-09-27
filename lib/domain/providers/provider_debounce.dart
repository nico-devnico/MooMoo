import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Attend [duration] avant de laisser passer la suite du `build`.
///
/// Les providers de recherche sont des familles indexées sur le texte saisi :
/// chaque caractère tapé crée une nouvelle instance et fait disposer la
/// précédente. En attendant ici, seule la saisie encore active au bout de
/// [duration] déclenche réellement la requête réseau ; les frappes
/// intermédiaires sont annulées via `ref.onDispose`.
///
/// Après l'attente, vérifier `ref.mounted` avant d'utiliser `ref`.
Future<void> debounce(
  Ref ref, [
  Duration duration = const Duration(milliseconds: 350),
]) {
  final completer = Completer<void>();
  final timer = Timer(duration, () {
    if (!completer.isCompleted) completer.complete();
  });
  ref.onDispose(() {
    timer.cancel();
    if (!completer.isCompleted) completer.complete();
  });
  return completer.future;
}
