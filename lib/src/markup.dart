String escape(String text) {
  return text.replaceAll('&', '&amp;').replaceAll('>', '&gt;').replaceAll('<', '&lt;').replaceAll('\'', '&#39;').replaceAll('"', '&#34;');
}

class Markup {
  const Markup(this.value);

  factory Markup.safe(Object? value) {
    return value is Markup ? value : Escaped(value);
  }

  final Object? value;

  @override
  int get hashCode {
    return value.hashCode;
  }

  @override
  bool operator ==(Object? other) {
    return other is Markup && value == other.value;
  }

  @override
  String toString() {
    return escape(value.toString());
  }
}

class Escaped implements Markup {
  Escaped(this.value);

  @override
  final Object? value;

  @override
  int get hashCode {
    return value.hashCode;
  }

  @override
  bool operator ==(Object? other) {
    return other is Markup && value == other.value;
  }

  @override
  String toString() {
    return value.toString();
  }
}
