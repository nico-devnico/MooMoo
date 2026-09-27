import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/contribution.dart';

/// Colonnes lues par les listes (mes contributions, modération admin).
/// `landmark_data` est exclu : c'est un jsonb lourd qu'aucune liste n'affiche.
const contributionListColumns =
    'id,contributor_id,sign_language_id,word,description,video_url,'
    'thumbnail_url,status,reviewer_id,reviewer_note,submitted_at,reviewed_at';

/// Colonnes nécessaires pour recopier une contribution approuvée dans `signs`.
const contributionDetailColumns = '$contributionListColumns,landmark_data';

abstract class ContributionRepository {
  Future<void> submitContribution(Contribution contribution);
  Future<List<Contribution>> getMyContributions(
    String userId, {
    int limit = 50,
    int offset = 0,
  });
  Stream<List<Contribution>> watchMyContributions(String userId);
}

class ContributionRepositoryImpl implements ContributionRepository {
  final SupabaseClient _supabase;

  ContributionRepositoryImpl(this._supabase);

  @override
  Future<void> submitContribution(Contribution contribution) async {
    await _supabase.from('contributions').insert(contribution.toJson());
  }

  @override
  Future<List<Contribution>> getMyContributions(
    String userId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _supabase
        .from('contributions')
        .select(contributionListColumns)
        .eq('contributor_id', userId)
        .order('submitted_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => Contribution.fromJson(json as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Stream<List<Contribution>> watchMyContributions(String userId) {
    return _supabase
        .from('contributions')
        .stream(primaryKey: ['id'])
        .eq('contributor_id', userId)
        .order('submitted_at', ascending: false)
        .limit(50)
        .map((data) => data
            .map((json) => Contribution.fromJson(json))
            .toList(growable: false));
  }
}
