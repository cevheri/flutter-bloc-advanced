import 'package:flutter_bloc_advance/core/errors/app_error.dart';

/// A sealed Result type for typed error handling without exceptions.
///
/// Usage:
/// ```dart
/// final result = await repository.getUser(id);
/// switch (result) {
///   case Success(:final data):
///     // handle data
///   case Failure(:final error):
///     // handle error
/// }
/// ```
sealed class Result<T> {
  const Result();

  /// Returns true if this is a [Success].
  bool get isSuccess => this is Success<T>;

  /// Returns true if this is a [Failure].
  bool get isFailure => this is Failure<T>;

  /// Returns the data if [Success], or null if [Failure].
  T? get dataOrNull => switch (this) {
    Success(:final data) => data,
    Failure() => null,
  };
}

/// Represents a successful result containing [data].
final class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;

  @override
  bool operator ==(Object other) => other is Success<T> && other.data == data;

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'Success($data)';
}

/// Represents a failed result containing an [AppError].
final class Failure<T> extends Result<T> {
  const Failure(this.error, {this.stackTrace});
  final AppError error;
  final StackTrace? stackTrace;

  @override
  bool operator ==(Object other) => other is Failure<T> && other.error == error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'Failure($error)';
}
