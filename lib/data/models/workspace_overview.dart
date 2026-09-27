int _int(Object? v) => (v as num?)?.toInt() ?? 0;
double? _double(Object? v) => (v as num?)?.toDouble();

/// `teacher_overview()`: aggregate learning statistics, no personal data.
class TeacherOverview {
  const TeacherOverview({
    required this.unitsTotal,
    required this.unitsPublished,
    required this.lessonsTotal,
    required this.learnersTotal,
    required this.completionsTotal,
    required this.completions7d,
    required this.averageScore,
    required this.lessons,
  });

  final int unitsTotal;
  final int unitsPublished;
  final int lessonsTotal;
  final int learnersTotal;
  final int completionsTotal;
  final int completions7d;
  final double? averageScore;
  final List<LessonStat> lessons;

  factory TeacherOverview.fromJson(Map<String, dynamic> json) => TeacherOverview(
        unitsTotal: _int(json['units_total']),
        unitsPublished: _int(json['units_published']),
        lessonsTotal: _int(json['lessons_total']),
        learnersTotal: _int(json['learners_total']),
        completionsTotal: _int(json['completions_total']),
        completions7d: _int(json['completions_7d']),
        averageScore: _double(json['average_score']),
        lessons: [
          for (final l in (json['lessons'] as List? ?? const []))
            LessonStat.fromJson(Map<String, dynamic>.from(l as Map)),
        ],
      );
}

class LessonStat {
  const LessonStat({
    required this.lessonTitle,
    required this.unitTitle,
    required this.unitPublished,
    required this.completions,
    required this.learners,
    required this.averageScore,
    required this.lastCompletedAt,
  });

  final String lessonTitle;
  final String unitTitle;
  final bool unitPublished;
  final int completions;
  final int learners;
  final double? averageScore;
  final DateTime? lastCompletedAt;

  factory LessonStat.fromJson(Map<String, dynamic> json) => LessonStat(
        lessonTitle: '${json['lesson_title'] ?? ''}',
        unitTitle: '${json['unit_title'] ?? ''}',
        unitPublished: json['unit_published'] == true,
        completions: _int(json['completions']),
        learners: _int(json['learners']),
        averageScore: _double(json['average_score']),
        lastCompletedAt: DateTime.tryParse('${json['last_completed_at'] ?? ''}'),
      );
}

/// `expert_overview()`: dictionary and moderation workload.
class ExpertOverview {
  const ExpertOverview({
    required this.pendingContributions,
    required this.reviewedByMe,
    required this.signsTotal,
    required this.signsPublished,
    required this.signsDraft,
    required this.signsWithoutVideo,
    required this.signsWithoutCategory,
    required this.categoriesTotal,
    required this.languages,
  });

  final int pendingContributions;
  final int reviewedByMe;
  final int signsTotal;
  final int signsPublished;
  final int signsDraft;
  final int signsWithoutVideo;
  final int signsWithoutCategory;
  final int categoriesTotal;
  final List<({String code, String name, int signs, int published})> languages;

  factory ExpertOverview.fromJson(Map<String, dynamic> json) => ExpertOverview(
        pendingContributions: _int(json['pending_contributions']),
        reviewedByMe: _int(json['reviewed_by_me']),
        signsTotal: _int(json['signs_total']),
        signsPublished: _int(json['signs_published']),
        signsDraft: _int(json['signs_draft']),
        signsWithoutVideo: _int(json['signs_without_video']),
        signsWithoutCategory: _int(json['signs_without_category']),
        categoriesTotal: _int(json['categories_total']),
        languages: [
          for (final l in (json['languages'] as List? ?? const []))
            (
              code: '${(l as Map)['code']}',
              name: '${l['name']}',
              signs: _int(l['signs']),
              published: _int(l['published']),
            ),
        ],
      );
}
