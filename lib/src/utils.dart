List<Object> slice(List<Object> list, int start, [int end, int step]) {
  final result = <Object>[];
  final length = list.length;

  end ??= length;
  step ??= 1;

  if (start < 0) {
    start = length + start;
  }

  if (end < 0) {
    end = length + end;
  }

  if (step > 0) {
    for (var i = start; i < end; i += step) {
      result.add(list[i]);
    }
  } else {
    step = -step;

    for (var i = end - 1; i >= start; i -= step) {
      result.add(list[i]);
    }
  }

  return list;
}
