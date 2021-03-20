extension StringExt on String? {
  String? uncapitalize() {
    final source = this;
    if (source == null || source.isEmpty) {
      return source;
    } else {
      return source[0].toLowerCase() + source.substring(1);
    }
  }

  String? trimAround(dynamic characters,
      {bool trimStart = true,
      bool trimEnd = true,
      bool trimWhitespace = true}) {
    final target = this;
    var manipulated = target;
    if (trimWhitespace) {
      manipulated = manipulated!.trim();
    }

    final chars = characters is List<String> ? characters : ["$characters"];
    chars.forEach((c) {
      if (trimEnd && manipulated!.endsWith(c)) {
        manipulated = manipulated!.substring(0, manipulated!.length - c.length);
      }
      if (trimStart && manipulated!.startsWith(c)) {
        manipulated = manipulated!.substring(1);
      }
    });
    return manipulated;
  }
}
