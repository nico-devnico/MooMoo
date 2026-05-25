import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:moomoo/core/constants/character_constants.dart';
import 'package:moomoo/data/models/character.dart';

part 'character_provider.g.dart';

@riverpod
Future<List<Character>> characters(Ref ref) async {
  List<Character> charactersList = [];

  try {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final modelPaths = manifest.listAssets()
        .where((String key) => key.contains('assets/models/') && key.endsWith('.glb'))
        .toList();

    debugPrint('Modèles trouvés dans le manifeste: $modelPaths');

    charactersList = modelPaths.map((path) {
      final filename = path.split('/').last;
      final name = filename.replaceAll('.glb', '');
      
      // Normalisation de l'ID : minuscule, pas d'espaces, pas d'accents
      final id = name.toLowerCase()
          .replaceAll(' ', '_')
          .replaceAll(RegExp(r'[àáâãäå]'), 'a')
          .replaceAll(RegExp(r'[èéêë]'), 'e')
          .replaceAll(RegExp(r'[ìíîï]'), 'i')
          .replaceAll(RegExp(r'[òóôõö]'), 'o')
          .replaceAll(RegExp(r'[ùúûü]'), 'u')
          .replaceAll(RegExp(r'[ç]'), 'c');

      return Character(
        id: id,
        name: name,
        modelPath: path,
      );
    }).toList();
  } catch (e) {
    debugPrint('Erreur lors du chargement dynamique des modèles: $e');
  }

  // Fallback si la détection dynamique échoue ou est vide
  if (charactersList.isEmpty) {
    debugPrint('Utilisation du fallback pour les personnages');
    charactersList = [
      const Character(
        id: 'alex',
        name: 'Alex',
        modelPath: 'assets/models/Alex.glb',
      ),
      const Character(
        id: 'charlene',
        name: 'Charlène',
        modelPath: 'assets/models/Charlene.glb',
      ),
      const Character(
        id: 'nico',
        name: 'Nico',
        modelPath: 'assets/models/Nico.glb',
      ),
    ];
  }

  charactersList.sort((a, b) => a.name.compareTo(b.name));
  return charactersList;
}

@riverpod
Future<Character?> characterById(Ref ref, String id) async {
  final allCharacters = await ref.watch(charactersProvider.future);
  try {
    return allCharacters.firstWhere((c) => c.id == id);
  } catch (_) {
    return allCharacters.isNotEmpty ? allCharacters.first : null;
  }
}
