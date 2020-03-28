part of '../tokenizer.dart';

typedef MapWithStartCallback<T, R> = R Function(int start, T value);

extension MapWithStartParserExtension<T> on Parser<T> {
  Parser<R> mapWithStart<R>(MapWithStartCallback<T, R> callback, {bool hasSideEffects = false}) =>
      MapWithStartParser<T, R>(this, callback, hasSideEffects);
}

class MapWithStartParser<T, R> extends DelegateParser<R> {
  MapWithStartParser(Parser<T> delegate, this.callback, [this.hasSideEffects = false])
      : assert(callback != null, 'callback must not be null'),
        assert(hasSideEffects != null, 'hasSideEffects must not be null'),
        super(delegate);

  final MapWithStartCallback<T, R> callback;

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
    return hasSideEffects ? super.fastParseOn(buffer, position) : delegate.fastParseOn(buffer, position);
  }

  @override
  MapWithStartParser<T, R> copy() => MapWithStartParser<T, R>(delegate as Parser<T>, callback, hasSideEffects);

  @override
  bool hasEqualProperties(MapWithStartParser<T, R> other) =>
      super.hasEqualProperties(other) && callback == other.callback && hasSideEffects == other.hasSideEffects;
}
