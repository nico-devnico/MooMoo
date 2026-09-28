import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/admin_stats.dart';
import '../models/contribution.dart';
import '../models/sign.dart';
import '../models/user_profile.dart';
import '../services/api_client.dart';
import 'contribution_repository.dart';
import 'dictionary_repository.dart';

/// Rôles cumulables stockés dans `public.user_roles`.
class AppRole {
  AppRole._();

  static const admin = 'admin';
  static const teacher = 'teacher';
  static const signExpert = 'sign_expert';

  /// Propriétaire du système : jamais attribuable depuis l'app, il se transmet
  /// par `transfer_ownership()` et la base le protège.
  static const superAdmin = 'super_admin';

  static const all = <String>[admin, teacher, signExpert];
}

/// Levée quand une action se verrouillerait elle-même dehors.
class AdminGuardException implements Exception {
  AdminGuardException(this.code, this.message);

  /// `self_demote`, `last_admin`, `self_suspend` ou `self_delete`.
  final String code;
  final String message;

  @override
  String toString() => message;
}

/// Colonnes de la liste admin des signes : tout sauf `landmark_data`, qui est
/// un jsonb lourd inutile pour la liste (l'éditeur le conserve tel quel).
const adminSignColumns =
    '$signListColumns,model_3d_url,tags,example_sentence,contributor_id,'
    'created_at,updated_at';

/// Colonnes affichées par la liste admin des utilisateurs.
const adminUserColumns =
    'id,email,display_name,avatar_url,bio,is_admin,is_deaf,status,'
    'suspended_at,suspended_reason,preferred_sign_language,created_at';

abstract class AdminRepository {
  Future<AdminStats> getStats();
  Future<List<UserProfile>> getUsers({
    String? query,
    String? status,
    int limit = 50,
    int offset = 0,
  });

  /// Nombre total de profils correspondant au filtre, compté côté serveur.
  Future<int> countUsers({String? query, String? status});
  Future<void> setUserAdmin(String userId, bool isAdmin);

  /// Remplace l'ensemble des rôles d'un utilisateur.
  Future<List<String>> setUserRoles(String userId, List<String> roles);

  Future<void> updateUserProfile(
    String userId, {
    String? displayName,
    String? bio,
    String? preferredSignLanguage,
    bool? isDeaf,
  });

  Future<void> suspendUser(String userId, {required String reason});
  Future<void> unsuspendUser(String userId);

  /// Passe par l'API Node : écrire dans `auth.users` exige la clé service role,
  /// qui ne doit jamais se trouver côté client.
  Future<String> createUser({
    required String email,
    required String password,
    String? displayName,
    bool isDeaf = false,
    List<String> roles = const [],
  });

  /// Passe également par l'API Node (clé service role obligatoire).
  Future<void> deleteUser(String userId);
  Future<List<Contribution>> getContributions({
    String? status,
    int limit = 50,
    int offset = 0,
  });
  Future<void> reviewContribution({
    required String contributionId,
    required String status,
    required String reviewerId,
    String? note,
    bool createSignOnApprove = true,
  });
  Future<List<Sign>> getSigns({
    String? query,
    bool? isValidated,
    int? languageId,
    int? categoryId,
    int limit = 50,
    int offset = 0,
  });
  Future<void> setSignValidated(String signId, bool isValidated);
  Future<void> deleteSign(String signId);
  Future<Sign> upsertSign(Sign sign);
}

class AdminRepositoryImpl implements AdminRepository {
  final SupabaseClient _supabase;
  final ApiClient _api;

  AdminRepositoryImpl(this._supabase, {ApiClient? api})
      : _api = api ?? ApiClient();

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  String get _accessToken {
    final token = _supabase.auth.currentSession?.accessToken;
    if (token == null || token.isEmpty) {
      throw AdminGuardException('unauthenticated', 'Session expirée');
    }
    return token;
  }

  /// Un seul aller-retour via la fonction SQL `admin_stats()`. Si la migration
  /// n'est pas encore appliquée, on retombe sur six `count` exacts lancés en
  /// parallèle (aucune ligne rapatriée, contrairement à l'ancienne version qui
  /// téléchargeait toutes les lignes de `signs` et `contributions`).
  @override
  Future<AdminStats> getStats() async {
    try {
      final rpc = await _supabase.rpc('admin_stats');
      if (rpc is Map) {
        return AdminStats(
          usersCount: (rpc['users_count'] as num?)?.toInt() ?? 0,
          signsCount: (rpc['signs_count'] as num?)?.toInt() ?? 0,
          validatedSignsCount:
              (rpc['validated_signs_count'] as num?)?.toInt() ?? 0,
          pendingContributionsCount:
              (rpc['pending_contributions_count'] as num?)?.toInt() ?? 0,
          approvedContributionsCount:
              (rpc['approved_contributions_count'] as num?)?.toInt() ?? 0,
          rejectedContributionsCount:
              (rpc['rejected_contributions_count'] as num?)?.toInt() ?? 0,
        );
      }
    } catch (_) {
      // La fonction n'existe pas (migration non appliquée) : on compte côté
      // serveur avec des requêtes HEAD parallèles.
    }

    final counts = await Future.wait([
      _supabase.from('profiles').count(CountOption.exact),
      _supabase.from('signs').count(CountOption.exact),
      _supabase.from('signs').count(CountOption.exact).eq('is_validated', true),
      _supabase.from('contributions').count(CountOption.exact).eq('status', 'pending'),
      _supabase.from('contributions').count(CountOption.exact).eq('status', 'approved'),
      _supabase.from('contributions').count(CountOption.exact).eq('status', 'rejected'),
    ]);

    return AdminStats(
      usersCount: counts[0],
      signsCount: counts[1],
      validatedSignsCount: counts[2],
      pendingContributionsCount: counts[3],
      approvedContributionsCount: counts[4],
      rejectedContributionsCount: counts[5],
    );
  }

  @override
  Future<List<UserProfile>> getUsers({
    String? query,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    var request = _supabase.from('profiles').select(adminUserColumns);

    // Le filtre était appliqué en Dart après avoir rapatrié 50 profils : on le
    // pousse côté serveur pour que la limite porte sur les lignes utiles.
    final q = query?.trim();
    if (q != null && q.isNotEmpty) {
      request = request.or(
        'display_name.ilike.%${_escapeFilter(q)}%,email.ilike.%${_escapeFilter(q)}%',
      );
    }
    if (status != null && status.isNotEmpty) {
      request = request.eq('status', status);
    }

    final response = await request
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    final profiles = (response as List)
        .map((json) => UserProfile.fromJson(json as Map<String, dynamic>))
        .toList(growable: false);
    if (profiles.isEmpty) return profiles;

    // Une seule requête pour les rôles de la page entière, plutôt qu'une par
    // profil ou une jointure qui ramènerait des colonnes inutiles.
    final roles = await _rolesFor(profiles.map((p) => p.id).toList());
    return profiles
        .map((p) => p.copyWith(roles: roles[p.id] ?? const <String>[]))
        .toList(growable: false);
  }

  @override
  Future<int> countUsers({String? query, String? status}) async {
    var request = _supabase.from('profiles').count(CountOption.exact);
    final q = query?.trim();
    if (q != null && q.isNotEmpty) {
      request = request.or(
        'display_name.ilike.%${_escapeFilter(q)}%,email.ilike.%${_escapeFilter(q)}%',
      );
    }
    if (status != null && status.isNotEmpty) {
      request = request.eq('status', status);
    }
    return request;
  }

  String _escapeFilter(String value) =>
      value.replaceAll(',', ' ').replaceAll('%', '');

  Future<Map<String, List<String>>> _rolesFor(List<String> userIds) async {
    final rows = await _supabase
        .from('user_roles')
        .select('user_id,role')
        .inFilter('user_id', userIds);

    final grouped = <String, List<String>>{};
    for (final row in rows as List) {
      final map = row as Map<String, dynamic>;
      grouped
          .putIfAbsent(map['user_id'] as String, () => <String>[])
          .add(map['role'] as String);
    }
    for (final list in grouped.values) {
      list.sort();
    }
    return grouped;
  }

  @override
  Future<void> setUserAdmin(String userId, bool isAdmin) async {
    final current = (await _rolesFor([userId]))[userId] ?? const <String>[];
    final next = isAdmin
        ? {...current, AppRole.admin}.toList()
        : current.where((r) => r != AppRole.admin).toList();
    await setUserRoles(userId, next);
  }

  /// `profiles.is_admin` est maintenu par le trigger `sync_profile_admin_flag`,
  /// on n'écrit donc jamais la colonne directement.
  @override
  Future<List<String>> setUserRoles(String userId, List<String> roles) async {
    final requested = {...roles}.where(AppRole.all.contains).toList()..sort();
    final current = ((await _rolesFor([userId]))[userId] ?? const <String>[])
        .where(AppRole.all.contains)
        .toList();

    final losesAdmin =
        current.contains(AppRole.admin) && !requested.contains(AppRole.admin);
    if (losesAdmin) {
      // Mêmes garde-fous que l'API Node : ce chemin passe directement par
      // Supabase, il ne bénéficie donc pas de ceux du backend.
      if (userId == _currentUserId) {
        throw AdminGuardException(
          'self_demote',
          'Un admin ne peut pas retirer son propre rôle admin',
        );
      }
      final remaining = await _supabase
          .from('profiles')
          .count(CountOption.exact)
          .eq('is_admin', true)
          .neq('id', userId);
      if (remaining == 0) {
        throw AdminGuardException(
          'last_admin',
          'Impossible de retirer le dernier admin du système',
        );
      }
    }

    final toRemove = current.where((r) => !requested.contains(r)).toList();
    if (toRemove.isNotEmpty) {
      await _supabase
          .from('user_roles')
          .delete()
          .eq('user_id', userId)
          .inFilter('role', toRemove);
    }

    final toAdd = requested.where((r) => !current.contains(r)).toList();
    if (toAdd.isNotEmpty) {
      await _supabase.from('user_roles').upsert(
            [
              for (final role in toAdd)
                {
                  'user_id': userId,
                  'role': role,
                  'granted_by': ?_currentUserId,
                },
            ],
            onConflict: 'user_id,role',
          );
    }

    return requested;
  }

  @override
  Future<void> updateUserProfile(
    String userId, {
    String? displayName,
    String? bio,
    String? preferredSignLanguage,
    bool? isDeaf,
  }) async {
    await _supabase.from('profiles').update({
      'display_name': ?displayName?.trim(),
      if (bio != null) 'bio': bio.trim().isEmpty ? null : bio.trim(),
      'preferred_sign_language': ?preferredSignLanguage,
      'is_deaf': ?isDeaf,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  @override
  Future<void> suspendUser(String userId, {required String reason}) async {
    if (userId == _currentUserId) {
      throw AdminGuardException(
        'self_suspend',
        'Un admin ne peut pas se suspendre lui-même',
      );
    }
    await _supabase.from('profiles').update({
      'status': 'suspended',
      'suspended_at': DateTime.now().toIso8601String(),
      'suspended_reason': reason.trim(),
      'suspended_by': ?_currentUserId,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  @override
  Future<void> unsuspendUser(String userId) async {
    await _supabase.from('profiles').update({
      'status': 'active',
      'suspended_at': null,
      'suspended_reason': null,
      'suspended_by': null,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  @override
  Future<String> createUser({
    required String email,
    required String password,
    String? displayName,
    bool isDeaf = false,
    List<String> roles = const [],
  }) async {
    final response = await _api.postJson(
      '/api/admin/users',
      accessToken: _accessToken,
      body: {
        'email': email.trim(),
        'password': password,
        'displayName': ?displayName,
        'isDeaf': isDeaf,
        'roles': roles.where(AppRole.all.contains).toList(),
      },
    );
    final user = response['user'];
    if (user is Map && user['id'] is String) return user['id'] as String;
    throw ApiException(500, 'Réponse inattendue de /api/admin/users');
  }

  @override
  Future<void> deleteUser(String userId) async {
    if (userId == _currentUserId) {
      throw AdminGuardException(
        'self_delete',
        'Un admin ne peut pas supprimer son propre compte',
      );
    }
    await _api.delete('/api/admin/users/$userId', accessToken: _accessToken);
  }

  @override
  Future<List<Contribution>> getContributions({
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    var request = _supabase.from('contributions').select(contributionListColumns);

    if (status != null && status.isNotEmpty) {
      request = request.eq('status', status);
    }

    final response = await request
        .order('submitted_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => Contribution.fromJson(json as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<void> reviewContribution({
    required String contributionId,
    required String status,
    required String reviewerId,
    String? note,
    bool createSignOnApprove = true,
  }) async {
    final now = DateTime.now().toIso8601String();
    final needsRow = status == 'approved' && createSignOnApprove;

    // L'update renvoie directement la ligne (`.select()`), ce qui supprime le
    // second aller-retour qui servait uniquement à relire la contribution.
    final updated = await _supabase
        .from('contributions')
        .update({
          'status': status,
          'reviewer_id': reviewerId,
          'reviewer_note': note,
          'reviewed_at': now,
        })
        .eq('id', contributionId)
        .select(needsRow ? contributionDetailColumns : 'id')
        .maybeSingle();

    if (updated == null) {
      throw const PostgrestException(
        message: 'Revue refusée : rôle administrateur ou expert requis',
        code: '42501',
      );
    }
    if (!needsRow) return;

    final contribution = Contribution.fromJson(updated);
    final sign = Sign(
      id: const Uuid().v4(),
      signLanguageId: contribution.signLanguageId,
      word: contribution.word,
      description: contribution.description,
      videoUrl: contribution.videoUrl,
      thumbnailUrl: contribution.thumbnailUrl,
      landmarkData: contribution.landmarkData,
      isValidated: true,
      contributorId: contribution.contributorId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _supabase.from('signs').insert(sign.toJson());
  }

  @override
  Future<List<Sign>> getSigns({
    String? query,
    bool? isValidated,
    int? languageId,
    int? categoryId,
    int limit = 50,
    int offset = 0,
  }) async {
    var request = _supabase.from('signs').select(adminSignColumns);

    if (isValidated != null) {
      request = request.eq('is_validated', isValidated);
    }
    if (languageId != null) request = request.eq('sign_language_id', languageId);
    if (categoryId != null) request = request.eq('category_id', categoryId);
    final trimmed = query?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      request = request.ilike('word', '%$trimmed%');
    }

    final response = await request
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => Sign.fromJson(json as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<void> setSignValidated(String signId, bool isValidated) async {
    final rows = await _supabase.from('signs').update({
      'is_validated': isValidated,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', signId).select('id');
    if (rows.isEmpty) {
      throw const PostgrestException(message: 'Modification refusée', code: '42501');
    }
  }

  @override
  Future<void> deleteSign(String signId) async {
    final rows = await _supabase.from('signs').delete().eq('id', signId).select('id');
    if (rows.isEmpty) {
      throw const PostgrestException(
        message: 'Suppression refusée : réservée aux administrateurs',
        code: '42501',
      );
    }
  }

  @override
  Future<Sign> upsertSign(Sign sign) async {
    final json = sign.toJson();
    json['updated_at'] = DateTime.now().toIso8601String();
    // La liste admin ne charge pas `landmark_data` : ne pas l'écraser avec null
    // quand l'éditeur renvoie un signe issu de cette liste.
    if (json['landmark_data'] == null) json.remove('landmark_data');

    final response =
        await _supabase.from('signs').upsert(json).select(adminSignColumns).single();
    return Sign.fromJson(response);
  }
}
