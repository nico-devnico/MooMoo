import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/contribution.dart';

abstract class ContributionRepository {
  Future<void> submitContribution(Contribution contribution);
  Future<List<Contribution>> getMyContributions(String userId);
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
  Future<List<Contribution>> getMyContributions(String userId) async {
    final response = await _supabase
        .from('contributions')
        .select()
        .eq('contributor_id', userId)
        .order('submitted_at', ascending: false);
    
    return (response as List).map((json) => Contribution.fromJson(json)).toList();
  }

  @override
  Stream<List<Contribution>> watchMyContributions(String userId) {
    return _supabase
        .from('contributions')
        .stream(primaryKey: ['id'])
        .eq('contributor_id', userId)
        .order('submitted_at', ascending: false)
        .map((data) => data.map((json) => Contribution.fromJson(json)).toList());
  }
}
