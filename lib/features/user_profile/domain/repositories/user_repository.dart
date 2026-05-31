import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_profile.dart';

abstract interface class UserRepository {
  FutureEither<UserProfile> getUserProfile(String userId);
  FutureEitherVoid updateWhatsApp({required String userId, required String phoneE164});
}
