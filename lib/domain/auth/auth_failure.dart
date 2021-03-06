import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_failure.freezed.dart';

@freezed
abstract class AuthFailure with _$AuthFailure {
  const factory AuthFailure.cancelledByUser() = CancelledByUser;
  // Serves as a "catch all" failure if we don't know what exactly went wrong
  const factory AuthFailure.serverError() = ServerError;

  const factory AuthFailure.invalidVerificationCode() = InvalidVerificationCode;
  const factory AuthFailure.invalidCellPhoneNumber() = InvalidCellPhoneNumber;

  const factory AuthFailure.phoneAlreadyInUse() = PhoneAlreadyInUse;
  const factory AuthFailure.invalidMobileAndSMSCodeCombination() =
      InvalidMobileAndSMSCodeCombination;
}
