import 'package:fpdart/fpdart.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_local_datasource.dart';

class UserRepositoryImpl implements UserRepository {
  final UserLocalDataSource _dataSource;
  const UserRepositoryImpl(this._dataSource);

  @override
  FutureEither<UserProfile> getUserProfile(String userId) async {
    try {
      final model = await _dataSource.getUserProfile(userId);
      return right(model);
    } on NotFoundException catch (e) {
      return left(NotFoundFailure(e.message));
    } on DatabaseException catch (e) {
      return left(DatabaseFailure(e.message));
    } on Exception catch (e) {
      return left(e.toFailure());
    }
  }

  @override
  FutureEitherVoid updateWhatsApp({
    required String userId,
    required String phoneE164,
  }) async {
    try {
      await _dataSource.updateWhatsApp(userId, phoneE164);
      return right(unit);
    } on DatabaseException catch (e) {
      return left(DatabaseFailure(e.message));
    } on Exception catch (e) {
      return left(e.toFailure());
    }
  }
}
