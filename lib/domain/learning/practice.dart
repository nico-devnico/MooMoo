import '../../data/models/ml_model.dart';

/// Durée pendant laquelle l'apprenant signe devant la caméra (exercice pratique).
const Duration practiceRecordingDuration = Duration(seconds: 3);

/// Secondes du compte à rebours avant l'enregistrement, pour se préparer.
const int practiceCountdown = 3;

/// Indique si le signe reconnu correspond au signe attendu.
///
/// Un signe d'apprenant est rarement parfait : on accepte le mot s'il figure
/// parmi les [tolerance] meilleures prédictions du modèle (en plus du label
/// principal).
bool practiceMatches(String expectedWord, InferenceResult result, {int tolerance = 3}) {
  // Inférence en échec → pas de correspondance.
  if (!result.ok) return false;
  // Normalise le mot attendu (accents, ponctuation, casse).
  final target = normalizeSignWord(expectedWord);
  if (target.isEmpty) return false;
  // Candidats : libellé principal + top-N du modèle.
  final candidates = [
    ?result.label,
    ...result.topLabels.take(tolerance),
  ];
  // Au moins un candidat normalisé doit égaler la cible.
  return candidates.any((c) => normalizeSignWord(c) == target);
}

/// Normalise un mot de signe : minuscules, sans accents, espaces ni ponctuation.
/// Exemple : « Ça va ? » → « cava ».
String normalizeSignWord(String word) {
  // Table de remplacement des caractères accentués courants (FR + voisins).
  const accents = {
    'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ã': 'a',
    'ç': 'c',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'î': 'i', 'ï': 'i', 'í': 'i',
    'ô': 'o', 'ö': 'o', 'ó': 'o', 'õ': 'o',
    'ù': 'u', 'û': 'u', 'ü': 'u', 'ú': 'u',
    'ÿ': 'y', 'ñ': 'n', 'œ': 'oe', 'æ': 'ae',
  };
  final buffer = StringBuffer();
  // Parcourt chaque caractère après trim + minuscules.
  for (final char in word.trim().toLowerCase().split('')) {
    // Remplace l'accent s'il existe, sinon garde le caractère tel quel.
    final plain = accents[char] ?? char;
    // Ne conserve que lettres a–z et chiffres (ignore espaces / ponctuation).
    if (RegExp(r'[a-z0-9]').hasMatch(plain)) buffer.write(plain);
  }
  return buffer.toString();
}
