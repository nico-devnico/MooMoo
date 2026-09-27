import 'sign.dart';

/// A chapter of the learning path, e.g. "Greetings". Holds its lessons in
/// display order.
class LearningUnit {
  final String id;
  final int signLanguageId;
  final String title;
  final String? description;
  final String? iconName;
  final int orderIndex;
  final bool isPublished;
  final List<LearningLesson> lessons;

  const LearningUnit({
    required this.id,
    required this.signLanguageId,
    required this.title,
    this.description,
    this.iconName,
    this.orderIndex = 0,
    this.isPublished = false,
    this.lessons = const [],
  });

  factory LearningUnit.fromJson(Map<String, dynamic> json) {
    final lessons = (json['learning_lessons'] as List? ?? const [])
        .map((l) => LearningLesson.fromJson(l as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    return LearningUnit(
      id: json['id'] as String,
      signLanguageId: json['sign_language_id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      iconName: json['icon_name'] as String?,
      orderIndex: json['order_index'] as int? ?? 0,
      isPublished: json['is_published'] as bool? ?? false,
      lessons: List.unmodifiable(lessons),
    );
  }
}

class LearningLesson {
  final String id;
  final String unitId;
  final String title;
  final String? description;
  final int orderIndex;
  final int xpReward;
  final int signCount;

  const LearningLesson({
    required this.id,
    required this.unitId,
    required this.title,
    this.description,
    this.orderIndex = 0,
    this.xpReward = 10,
    this.signCount = 0,
  });

  factory LearningLesson.fromJson(Map<String, dynamic> json) {
    // PostgREST renvoie l'agrégat `lesson_signs(count)` sous la forme
    // [{"count": n}].
    final counts = json['lesson_signs'];
    final signCount = counts is List && counts.isNotEmpty
        ? (counts.first as Map<String, dynamic>)['count'] as int? ?? 0
        : 0;

    return LearningLesson(
      id: json['id'] as String,
      unitId: json['unit_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      orderIndex: json['order_index'] as int? ?? 0,
      xpReward: json['xp_reward'] as int? ?? 10,
      signCount: signCount,
    );
  }
}

/// Best result the current user reached on one lesson.
class LessonProgress {
  final String lessonId;
  final int bestCorrect;
  final int questionCount;
  final int completions;

  const LessonProgress({
    required this.lessonId,
    required this.bestCorrect,
    required this.questionCount,
    required this.completions,
  });

  bool get isPerfect => bestCorrect == questionCount;

  factory LessonProgress.fromJson(Map<String, dynamic> json) => LessonProgress(
        lessonId: json['lesson_id'] as String,
        bestCorrect: json['best_correct'] as int,
        questionCount: json['question_count'] as int,
        completions: json['completions'] as int,
      );
}

class LearnerSummary {
  final int totalXp;
  final int currentStreak;
  final int longestStreak;
  final int dailyGoalXp;
  final int todayXp;
  final int lessonsCompleted;
  final bool activeToday;

  const LearnerSummary({
    this.totalXp = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.dailyGoalXp = 20,
    this.todayXp = 0,
    this.lessonsCompleted = 0,
    this.activeToday = false,
  });

  double get dailyGoalProgress =>
      dailyGoalXp == 0 ? 0 : (todayXp / dailyGoalXp).clamp(0.0, 1.0);

  bool get dailyGoalReached => todayXp >= dailyGoalXp;

  factory LearnerSummary.fromJson(Map<String, dynamic> json) => LearnerSummary(
        totalXp: json['total_xp'] as int? ?? 0,
        currentStreak: json['current_streak'] as int? ?? 0,
        longestStreak: json['longest_streak'] as int? ?? 0,
        dailyGoalXp: json['daily_goal_xp'] as int? ?? 20,
        todayXp: json['today_xp'] as int? ?? 0,
        lessonsCompleted: json['lessons_completed'] as int? ?? 0,
        activeToday: json['active_today'] as bool? ?? false,
      );
}

/// Everything the lesson player needs: the lesson, the signs it teaches and
/// extra signs of the same language used as wrong answers.
class LessonContent {
  final String id;
  final String title;
  final int xpReward;
  final int signLanguageId;
  final List<Sign> signs;
  final List<Sign> distractors;

  const LessonContent({
    required this.id,
    required this.title,
    required this.xpReward,
    required this.signLanguageId,
    required this.signs,
    required this.distractors,
  });
}

class LessonResult {
  final int xpEarned;
  final bool isFirstCompletion;
  final LearnerSummary summary;

  const LessonResult({
    required this.xpEarned,
    required this.isFirstCompletion,
    required this.summary,
  });

  factory LessonResult.fromJson(Map<String, dynamic> json) => LessonResult(
        xpEarned: json['xp_earned'] as int? ?? 0,
        isFirstCompletion: json['is_first_completion'] as bool? ?? false,
        summary: LearnerSummary.fromJson(
          (json['summary'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
      );
}
