part of 'scanner.dart';

typedef MapWithOffsetCallback<T, R> = R Function(int offset, T value);

extension MapWithOffsetParserExtension<T> on Parser<T> {
  Parser<R> mapWithOffset<R>(MapWithOffsetCallback<T, R> callback,
          {bool hasSideEffects = false}) =>
      MapWithOffsetParser<T, R>(this, callback, hasSideEffects);
}

class MapWithOffsetParser<T, R> extends DelegateParser<R> {
  MapWithOffsetParser(Parser<T> delegate, this.callback,
      [this.hasSideEffects = false])
      : assert(callback != null, 'callback must not be null'),
        assert(hasSideEffects != null, 'hasSideEffects must not be null'),
        super(delegate);

  final MapWithOffsetCallback<T, R> callback;

  final bool hasSideEffects;

  @override
  Result<R> parseOn(Context context) {
    final Result<Object> result = delegate.parseOn(context);

    if (result.isSuccess) {
      return result.success(callback(context.position, result.value as T));
    } else {
      return result.failure(result.message);
    }
  }

  @override
  int fastParseOn(String buffer, int position) {
    return hasSideEffects
        ? super.fastParseOn(buffer, position)
        : delegate.fastParseOn(buffer, position);
  }

  @override
  MapWithOffsetParser<T, R> copy() => MapWithOffsetParser<T, R>(
      delegate as Parser<T>, callback, hasSideEffects);

  @override
  bool hasEqualProperties(MapWithOffsetParser<T, R> other) =>
      super.hasEqualProperties(other) &&
      callback == other.callback &&
      hasSideEffects == other.hasSideEffects;
}
