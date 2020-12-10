import 'package:example/path_and_entity.dart';
import 'package:flutter/widgets.dart';

void main() {
  final widget = EntityPage(routeId: "Hello");
  final res = widget.build(null);
  assert(res is Text);
  assert((res as Text).data == "Hello");
}
