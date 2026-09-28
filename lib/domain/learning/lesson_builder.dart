import 'dart:math';

import '../../data/models/learning.dart';
import '../../data/models/sign.dart';
import '../../data/models/sign_landmarks.dart';

/// Une étape (écran) d'une leçon.
sealed class LessonStep {
  const LessonStep(this.sign, {this.isRetry = false});

  /// Signe enseigné ou demandé.
  final Sign sign;

  /// Question reposée après une erreur. Doit être réussie pour finir la leçon
  /// mais ne compte pas dans le score.
  final bool isRetry;

  /// Compte dans le score (questions de quiz et exercices pratiques).
  bool get isQuestion => this is! IntroStep;

  /// Renvoie une copie marquée comme nouvelle tentative (retry).
  LessonStep asRetry();
}

/// Exercice pratique en fin de leçon : l'apprenant réalise le signe devant
/// la caméra (ou s'auto-évalue si la reconnaissance est indisponible).
class PracticeStep extends LessonStep {
  const PracticeStep(super.sign, {required this.number, required this.total});

  /// Rang dans la séance d'exercice, à partir de 1.
  final int number;

  /// Nombre total d'exercices dans cette séance.
  final int total;

  @override
  // Un exercice ne se « rejoue » pas comme une question : on garde l'instance.
  LessonStep asRetry() => this;
}

/// Présente un nouveau signe et sa signification. Rien à répondre.
class IntroStep extends LessonStep {
  const IntroStep(super.sign);

  @override
  LessonStep asRetry() => this;
}

/// Montre un signe ; l'apprenant choisit le mot correspondant.
class RecognizeStep extends LessonStep {
  const RecognizeStep(super.sign, {required this.options, super.isRetry});

  /// Options de réponse (dont la bonne).
  final List<Sign> options;

  @override
  LessonStep asRetry() => RecognizeStep(sign, options: options, isRetry: true);
}

/// Montre un mot ; l'apprenant choisit le signe correspondant.
class FindStep extends LessonStep {
  const FindStep(super.sign, {required this.options, super.isRetry});

  /// Options de réponse (dont la bonne).
  final List<Sign> options;

  @override
  LessonStep asRetry() => FindStep(sign, options: options, isRetry: true);
}

/// Nombre max de choix proposés dans une question.
const int maxOptions = 4;

/// L'exercice est la partie la plus exigeante : quelques signes suffisent.
const int maxPracticeSigns = 3;

/// True si le signe a un média affichable (vidéo, miniature ou landmarks).
bool signHasVisual(Sign sign) {
  if (sign.videoUrl != null || sign.thumbnailUrl != null) return true;
  return !SignLandmarks.parse(sign.landmarkData).isEmpty;
}

/// Construit la leçon :
/// 1. chaque signe est introduit puis reconnu tout de suite ;
/// 2. une manche demande de retrouver chaque signe à partir du mot (ordre mélangé) ;
/// 3. une séance d'exercice clôt la leçon : reproduire les signes appris
///    avant de passer à la leçon suivante.
///
/// Les questions nécessitent au moins deux mots distincts ; sinon la leçon
/// se limite aux introductions (pas de question à une seule réponse).
List<LessonStep> buildLessonSteps(LessonContent content, {Random? random}) {
  final rng = random ?? Random();
  // Pool unique par mot : signes de la leçon + distracteurs.
  final pool = _uniqueByWord([...content.signs, ...content.distractors]);
  // Sous-ensemble avec média (pour les questions « trouver le signe »).
  final visualPool = pool.where(signHasVisual).toList(growable: false);

  final steps = <LessonStep>[];
  // Phase 1 : intro + reconnaissance pour chaque signe.
  for (final sign in content.signs) {
    steps.add(IntroStep(sign));
    if (signHasVisual(sign) && pool.length >= 2) {
      steps.add(RecognizeStep(sign, options: _pickOptions(sign, pool, rng)));
    }
  }

  // Phase 2 : manche « trouver le signe » dans un ordre aléatoire.
  final finalRound = [...content.signs]..shuffle(rng);
  for (final sign in finalRound) {
    if (signHasVisual(sign) && visualPool.length >= 2) {
      steps.add(FindStep(sign, options: _pickOptions(sign, visualPool, rng)));
    }
  }

  // Phase 3 : seuls les signes visualisables peuvent être reproduits.
  final practice = ([...content.signs.where(signHasVisual)]..shuffle(rng))
      .take(maxPracticeSigns)
      .toList(growable: false);
  for (var i = 0; i < practice.length; i++) {
    steps.add(PracticeStep(practice[i], number: i + 1, total: practice.length));
  }
  return steps;
}

/// Tire [maxOptions] choix : la bonne réponse + distracteurs mélangés.
List<Sign> _pickOptions(Sign answer, List<Sign> pool, Random rng) {
  final key = _wordKey(answer.word);
  final others = pool.where((s) => _wordKey(s.word) != key).toList()..shuffle(rng);
  return [answer, ...others.take(maxOptions - 1)]..shuffle(rng);
}

/// Déduplique une liste de signes par mot normalisé (casse / espaces).
List<Sign> _uniqueByWord(List<Sign> signs) {
  final seen = <String>{};
  return [
    for (final s in signs)
      if (seen.add(_wordKey(s.word))) s,
  ];
}

/// Clé de comparaison de mots : minuscules + trim.
String _wordKey(String word) => word.trim().toLowerCase();
