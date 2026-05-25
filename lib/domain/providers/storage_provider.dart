import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/storage_repository.dart';
import 'auth_provider.dart';

part 'storage_provider.g.dart';

@riverpod
StorageRepository storageRepository(Ref ref) {
  return StorageRepositoryImpl(ref.watch(supabaseClientProvider));
}
