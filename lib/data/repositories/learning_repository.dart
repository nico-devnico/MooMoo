import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/learning.dart';
import '../models/sign.dart';
import 'dictionary_repository.dart';

const _lessonColumns =
    'id,unit_id,title,description,order_index,xp_reward,lesson_signs(count)';

const _unitColumns =
    'id,sign_language_id,title,description,icon_name,order_index,is_published,'
    'learning_lessons($_lessonColumns)';

/// Signs used as wrong answers. Enough variety for four-choice questions
/// without pulling the whole dictionary.
const _distractorPoolSize = 24;

class LearningRepository {
  final SupabaseClient _supabase;

  LearningRepository(this._supabase);

  /// The device's offset, sent with every XP call so "today" and the streak
  /// follow the learner's own calendar rather than UTC.
  static int get _utcOffsetMinutes => DateTime.now().timeZoneOffset.inMinutes;

  Future<List<LearningUnit>> getPath(int languageId, {bool includeDrafts = false}) async {
    var request = _supabase
        .from('learning_units')
        .select(_unitColumns)
        .eq('sign_language_id', languageId);
    if (!includeDrafts) request = request.eq('is_published', true);

    final rows = await request.order('order_index').limit(200);
    return (rows as List)
        .map((json) => LearningUnit.fromJson(json as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<Map<String, LessonProgress>> getProgress() async {
    final rows = await _supabase.rpc('learning_progress') as List;
    return {
      for (final row in rows)
        (row as Map<String, dynamic>)['lesson_id'] as String:
            LessonProgress.fromJson(row),
    };
  }

  Future<LearnerSummary> getSummary() async {
    final json = await _supabase.rpc(
      'learner_summary',
      params: {'p_utc_offset_minutes': _utcOffsetMinutes},
    );
    return LearnerSummary.fromJson((json as Map).cast<String, dynamic>());
  }

  Future<LessonContent> getLessonContent(String lessonId) async {
    final row = await _supabase
        .from('learning_lessons')
        .select(
          'id,title,xp_reward,learning_units!inner(sign_language_id),'
          'lesson_signs(order_index,signs($signDetailColumns))',
        )
        .eq('id', lessonId)
        .single();

    final languageId =
        (row['learning_units'] as Map<String, dynamic>)['sign_language_id'] as int;

    // Un signe dévalidé depuis la création de la leçon revient à null (RLS) :
    // on l'écarte plutôt que de casser la leçon.
    final links = (row['lesson_signs'] as List)
        .cast<Map<String, dynamic>>()
        .where((link) => link['signs'] != null)
        .toList()
      ..sort((a, b) =>
          (a['order_index'] as int? ?? 0).compareTo(b['order_index'] as int? ?? 0));
    final signs = links
        .map((link) => Sign.fromJson(link['signs'] as Map<String, dynamic>))
        .toList(growable: false);

    var distractorQuery = _supabase
        .from('signs')
        .select(signListColumns)
        .eq('sign_language_id', languageId)
        .eq('is_validated', true);
    if (signs.isNotEmpty) {
      distractorQuery = distractorQuery.not(
        'id',
        'in',
        '(${signs.map((s) => s.id).join(',')})',
      );
    }
    final distractorRows = await distractorQuery.limit(_distractorPoolSize);

    return LessonContent(
      id: row['id'] as String,
      title: row['title'] as String,
      xpReward: row['xp_reward'] as int? ?? 10,
      signLanguageId: languageId,
      signs: signs,
      distractors: (distractorRows as List)
          .map((json) => Sign.fromJson(json as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  Future<LessonResult> completeLesson({
    required String lessonId,
    required int correct,
    required int total,
  }) async {
    final json = await _supabase.rpc('complete_lesson', params: {
      'p_lesson_id': lessonId,
      'p_correct': correct,
      'p_total': total,
      'p_utc_offset_minutes': _utcOffsetMinutes,
    });
    return LessonResult.fromJson((json as Map).cast<String, dynamic>());
  }

  Future<void> setDailyGoal(int goal) async {
    await _supabase.rpc('set_daily_goal', params: {'p_goal': goal});
  }

  Future<void> setLearningLanguage(String userId, String code) async {
    await _supabase
        .from('profiles')
        .update({'preferred_sign_language': code})
        .eq('id', userId);
  }

  Future<bool> canEdit() async {
    final result = await _supabase.rpc('current_user_can_edit_learning');
    return result == true;
  }

  // -------------------------------------------------------------------------
  // Édition du parcours (admins, enseignants, experts ; RLS l'impose)
  // -------------------------------------------------------------------------

  Future<void> saveUnit({
    String? id,
    required int signLanguageId,
    required String title,
    String? description,
    String? iconName,
    int? orderIndex,
    bool? isPublished,
  }) async {
    final values = <String, dynamic>{
      'sign_language_id': signLanguageId,
      'title': title.trim(),
      'description': _nullIfBlank(description),
      'icon_name': _nullIfBlank(iconName),
      'order_index': ?orderIndex,
      'is_published': ?isPublished,
    };
    if (id == null) {
      await _supabase.from('learning_units').insert(values);
    } else {
      await _supabase.from('learning_units').update(values).eq('id', id);
    }
  }

  Future<void> setUnitPublished(String id, bool published) async {
    await _supabase
        .from('learning_units')
        .update({'is_published': published})
        .eq('id', id);
  }

  Future<void> deleteUnit(String id) async {
    await _supabase.from('learning_units').delete().eq('id', id);
  }

  Future<void> saveLesson({
    String? id,
    required String unitId,
    required String title,
    String? description,
    int xpReward = 10,
    int? orderIndex,
  }) async {
    final values = <String, dynamic>{
      'unit_id': unitId,
      'title': title.trim(),
      'description': _nullIfBlank(description),
      'xp_reward': xpReward,
      'order_index': ?orderIndex,
    };
    if (id == null) {
      await _supabase.from('learning_lessons').insert(values);
    } else {
      await _supabase.from('learning_lessons').update(values).eq('id', id);
    }
  }

  Future<void> deleteLesson(String id) async {
    await _supabase.from('learning_lessons').delete().eq('id', id);
  }

  /// Rewrites `order_index` so rows follow [ids]. Units and lessons are a
  /// handful per level, one update each is cheaper than an RPC to maintain.
  Future<void> reorder(String table, List<String> ids) async {
    await Future.wait([
      for (var i = 0; i < ids.length; i++)
        _supabase.from(table).update({'order_index': i}).eq('id', ids[i]),
    ]);
  }

  Future<List<Sign>> getLessonSigns(String lessonId) async {
    final rows = await _supabase
        .from('lesson_signs')
        .select('order_index,signs($signListColumns)')
        .eq('lesson_id', lessonId)
        .order('order_index');
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .where((row) => row['signs'] != null)
        .map((row) => Sign.fromJson(row['signs'] as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<void> setLessonSigns(String lessonId, List<String> signIds) async {
    await _supabase.from('lesson_signs').delete().eq('lesson_id', lessonId);
    if (signIds.isEmpty) return;
    await _supabase.from('lesson_signs').insert([
      for (var i = 0; i < signIds.length; i++)
        {'lesson_id': lessonId, 'sign_id': signIds[i], 'order_index': i},
    ]);
  }

  static String? _nullIfBlank(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
