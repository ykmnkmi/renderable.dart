part of 'scanner.dart';

typedef MapWithStartCallback<T, R> = R Function(int start, T value);

extension MapWithStartParserExtension<T> on Parser<T> {
  Parser<R> mapWithStart<R>(MapWithStartCallback<T, R> callback,
          {bool hasSideEffects = false}) =>
      MapWithStartParser<T, R>(this, callback, hasSideEffects);
}

class MapWithStartParser<T, R> extends DelegateParser<R> {
  MapWithStartParser(Parser<T> delegate, this.callback,
      [this.hasSideEffects = false])
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
    return hasSideEffects
        ? super.fastParseOn(buffer, position)
        : delegate.fastParseOn(buffer, position);
  }

  @override
  MapWithStartParser<T, R> copy() =>
      MapWithStartParser<T, R>(delegate as Parser<T>, callback, hasSideEffects);

  @override
  bool hasEqualProperties(MapWithStartParser<T, R> other) =>
      super.hasEqualProperties(other) &&
      callback == other.callback &&
      hasSideEffects == other.hasSideEffects;
}

// extension InsertToParserExtension on Parser<Object> {
//   Parser<List<T>> insertTo<T>(Parser<List<T>> list) =>
//       InsertToParser<T>(this as Parser<T>, list);
// }

// class InsertToParser<T> extends DelegateParser<List<T>> {
//   final Parser<List<T>> list;

//   InsertToParser(Parser<T> delegate, this.list)
//       : assert(list != null, 'list must not be null'),
//         super(delegate);

//   @override
//   Result<List<T>> parseOn(Context context) {
//     final Result<Object> result = delegate.parseOn(context);
//     if (result.isSuccess) {
//       final input = result.value;
//       final output = input[index < 0 ? input.length + index : index];
//       return result.success(output);
//     } else {
//       return result.failure(result.message);
//     }
//   }

//   @override
//   int fastParseOn(String buffer, int position) =>
//       delegate.fastParseOn(buffer, position);

//   @override
//   InsertToParser<T> copy() => InsertToParser<T>(delegate as Parser<T>, list);

//   @override
//   bool hasEqualProperties(InsertToParser<T> other) =>
//       super.hasEqualProperties(other) && list == other.list;
// }
