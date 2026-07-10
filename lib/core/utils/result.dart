/// Lightweight Result type so repositories never throw into viewmodels.
sealed class Result<T> {
  const Result();

  R when<R>({
    required R Function(T data) success,
    required R Function(String message) failure,
  }) =>
      switch (this) {
        Success<T>(:final data) => success(data),
        Failure<T>(:final message) => failure(message),
      };

  T? get dataOrNull => switch (this) {
        Success<T>(:final data) => data,
        Failure<T>() => null,
      };

  bool get isSuccess => this is Success<T>;
}

class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

class Failure<T> extends Result<T> {
  const Failure(this.message);
  final String message;
}
