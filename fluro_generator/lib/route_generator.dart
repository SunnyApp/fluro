import 'package:analyzer/dart/element/element.dart';
import 'package:sunny_dart/sunny_dart.dart';
import 'package:sunny_fluro/annotations.dart';
import 'package:source_gen/source_gen.dart';
import 'package:sunny_fluro_generator/field_annotation_generator.dart';
import 'package:sunny_fluro_generator/route_params_generator.dart';

class RouteGenerator extends FieldAnnotationGenerator<route> {
  @override
  String generateForAnnotatedField(
      FieldElement field, ConstantReader annotation) {
    var mixin = <String>[];

    return null;
  }

// String delegateMethod(MethodElement method, String delegateName) {
//   var str =
//       "  ${method.returnType.getDisplayString(withNullability: false)} ${method.name}(";
//   bool hitPositional = false;
//   for (final p in method.parameters) {
//     if (p.isNamed && !hitPositional) {
//       str += "{";
//       hitPositional = true;
//     } else if (!p.isNamed && hitPositional) {
//       hitPositional = false;
//       str += "},";
//     }
//     str += "${p.type.getDisplayString(withNullability: false)} ${p.name},";
//   }
//   if (hitPositional) {
//     str += "}";
//   } else {
//     str = str.substring(0, str.length - 1);
//   }
//
//   str += ") => ${delegateName}.${method.name}(";
//   for (final p in method.parameters) {
//     if (p.isNamed) {
//       str += "${p.name}: ${p.name},";
//     } else {
//       str += "${p.name},";
//     }
//   }
//   str = str.substring(0, str.length - 1);
//   str += ");";
//   return str;
// }
}
