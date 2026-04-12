/// `Result<T, E>` — manejo de errores sin excepciones.
/// Uso: Result.ok(valor) / Result.err("mensaje")
sealed class Result<T, E> {
  const Result();

  static Result<T, E> ok<T, E>(T value) => Ok(value);
  static Result<T, E> err<T, E>(E error) => Err(error);

  bool get isOk => this is Ok<T, E>;
  bool get isErr => this is Err<T, E>;

  T get value => (this as Ok<T, E>).value;
  E get error => (this as Err<T, E>).error;

  R fold<R>(R Function(T) onOk, R Function(E) onErr) =>
      isOk ? onOk(value) : onErr(error);
}

final class Ok<T, E> extends Result<T, E> {
  @override
  final T value;
  const Ok(this.value);
}

final class Err<T, E> extends Result<T, E> {
  @override
  final E error;
  const Err(this.error);
}
