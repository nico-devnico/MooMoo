import '../../data/models/learning.dart';

/// Niveau d'acquisition d'une leçon, calculé à partir du meilleur score
/// (quiz + exercices pratiques inclus).
enum MasteryLevel {
  /// La leçon n'a jamais été terminée.
  none,

  /// Moins de 50 % : à revoir bientôt.
  fragile,

  /// Au moins 50 % de bonnes réponses.
  learning,

  /// Au moins 80 % de bonnes réponses.
  acquired,

  /// Toutes les réponses sont correctes (100 %).
  mastered,
}

/// Ratio de maîtrise entre 0 et 1 (meilleur score / nombre de questions).
/// Retourne 0 si aucun progrès n'est enregistré.
double masteryRatio(LessonProgress? progress) {
  // Pas de données ou leçon sans questions → rien à afficher.
  if (progress == null || progress.questionCount <= 0) return 0;
  // On borne entre 0 et 1 au cas où la base aurait des valeurs incohérentes.
  return (progress.bestCorrect / progress.questionCount).clamp(0.0, 1.0);
}

/// Convertit un progrès de leçon en [MasteryLevel] selon les seuils du parcours.
MasteryLevel masteryLevelOf(LessonProgress? progress) {
  // Sans progrès → niveau « aucun ».
  if (progress == null || progress.questionCount <= 0) return MasteryLevel.none;
  final ratio = masteryRatio(progress);
  // Seuils : 100 % → maîtrisé, 80 % → acquis, 50 % → en cours, sinon fragile.
  if (ratio >= 1) return MasteryLevel.mastered;
  if (ratio >= 0.8) return MasteryLevel.acquired;
  if (ratio >= 0.5) return MasteryLevel.learning;
  return MasteryLevel.fragile;
}

/// Nombre d'étoiles (sur 3) gagnées à la fin d'une leçon selon le score.
int starsFor(int correct, int total) {
  // Aucune question → on considère la leçon réussie (3 étoiles).
  if (total <= 0) return 3;
  final ratio = correct / total;
  // ≥ 90 % → 3 étoiles, ≥ 60 % → 2, sinon 1 (on récompense toujours l'effort).
  if (ratio >= 0.9) return 3;
  if (ratio >= 0.6) return 2;
  return 1;
}
