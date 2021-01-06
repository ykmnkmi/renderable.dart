void main() {
  Function.apply(Call(), [1, 2, 3]);
}

class Call {
  void call(List<dynamic> list) {
    print(list);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isMethod && invocation.memberName == #call) {
      call(invocation.positionalArguments);
      return;
    }

    return super.noSuchMethod(invocation);
  }
}
