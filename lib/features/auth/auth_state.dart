import 'package:pocketbase/pocketbase.dart';

/// Authentication state
enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
  error,
  registrationSuccess,
}

/// Authentication state class
class AuthState {
  final AuthStatus status;
  final RecordModel? user;
  final String? errorMessage;
  final String? successMessage;

  /// Creates an AuthState instance
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.successMessage,
  });

  /// Creates a copy of this AuthState but with the given fields replaced
  AuthState copyWith({
    AuthStatus? status,
    RecordModel? user,
    String? errorMessage,
    String? successMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      successMessage: successMessage ?? this.successMessage,
    );
  }

  /// Initial auth state
  static AuthState initial() => const AuthState(status: AuthStatus.initial);

  /// Loading auth state
  static AuthState loading() => const AuthState(status: AuthStatus.loading);

  /// Authenticated auth state
  static AuthState authenticated(RecordModel user) => AuthState(
        status: AuthStatus.authenticated,
        user: user,
      );

  /// Unauthenticated auth state
  static AuthState unauthenticated() => const AuthState(status: AuthStatus.unauthenticated);

  /// Error auth state
  static AuthState error(String message) => AuthState(
        status: AuthStatus.error,
        errorMessage: message,
      );
        
  /// Registration success state
  static AuthState registrationSuccess(String message) => AuthState(
        status: AuthStatus.registrationSuccess,
        successMessage: message,
      );
} 