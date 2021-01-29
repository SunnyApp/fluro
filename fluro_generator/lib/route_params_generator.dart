import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:flutter_degen/flutter_degen.dart';
import 'package:source_gen/source_gen.dart';
import 'package:sunny_fluro/annotations.dart';

String fieldName(Element element) {
  return element.name;
}

class RouteParamsGenerator extends GeneratorForAnnotation<routeParams> {
  @override
  dynamic generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    assert(
        element is ClassElement, "@routeParams must only be applied to class");
    final cls = element as ClassElement;
    assert(cls.isAbstract, "@routeParams must be applied to abstract classes");
    List<String> mixin = [];

    /// First letter is underscore
    final concreteName = element.name.substring(1);
    final fieldType = cls;

    final doesApply = (Element element) {
      return true;
    };

    var withStr = "";
    // if (pathParams.isNotEmpty) {
    //   withStr +=
    //       "with ${pathParams.map((e) => "_${e.getDisplayString(withNullability: false)}Mixin").join(", ")} ";
    // }
    mixin += [
      "class $concreteName extends ${element.name} implements RouteParams {",
    ];
    for (var ctr in cls.constructors) {
      mixin += [delegateConstructor(concreteName, ctr), ""];
    }
    mixin += [
      "  @override",
      "  dynamic operator [](String key) {",
      "    switch(key) {",
      for (var fld in cls.fields) ...[
        "      case \"${fieldName(fld)}\":",
        "        return ${fieldName(fld)};",
      ],
      "      default:",
      "        throw \"No parameter of that name \$key\";",
      "      }",
      "    }",
      "",
      "  @override",
      "  Map<String, dynamic> toMap() {",
      "    return {",
      for (var fld in cls.fields) ...[
        "      \"${fieldName(fld)}\": ${fieldName(fld)},",
      ],
      "    };",
      "    }",
      "",
      "    static $concreteName of(input) {",
      "    if(input is $concreteName) return input;",
      "    if(input==null) return null;",
      "    return $concreteName(",
      for (var fld in cls.fields) ...[
        "      ${fieldName(fld)}: input[\"${fieldName(fld)}\"] as ${fld.type.getDisplayString(withNullability: false)},",
      ],
      "    );",
      "    }",
    ];

    mixin += [
      // "  ${fieldType.name} get ${field.name};",
      "}",
    ];
    return mixin.join("\n");
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
