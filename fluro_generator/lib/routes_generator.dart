import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:flutter_degen/flutter_degen.dart';
import 'package:meta/meta.dart';
import 'package:source_gen/source_gen.dart';
import 'package:sunny_dart/sunny_dart.dart';
import 'package:sunny_fluro/annotations.dart';
import 'package:sunny_fluro_generator/fluro_generator.dart';
import 'package:sunny_fluro_generator/read_metadata.dart';

class RoutesGenerator extends GeneratorForAnnotation<routes> {
  @override
  dynamic generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    assert(element is ClassElement, "@routes must only be applied to class");
    final cls = element as ClassElement;
    assert(cls.isAbstract, "@routes must be applied to abstract classes");
    List<String> mixin = [];

    /// First letter is underscore
    final concreteName = element.name.substring(1);
    // ignore: unused_local_variable
    final fieldType = cls;

    final fieldsToProcess = cls.fields.mapNotNull((fld) {
      final metasrc = fld.isSynthetic ? fld.getter : fld;
      final annotated = metasrc.readAnnotation<route>();
      return annotated.hasAnnotation ? annotated : null;
    });

    mixin += [
      "class $concreteName extends ${element.name} {",
      "",
      for (var fld in fieldsToProcess) ...[
        "  @override",
        "  final ${fieldName(fld.element).capitalize()}Route ${fieldName(fld.element)};",
        "",
      ],
      "",
      "  $concreteName(FRouter router): ",
      fieldsToProcess
          .map((fld) =>
              "    ${fieldName(fld.element)} =  router.register(${fieldName(fld.element).capitalize()}Route())")
          .join(",\n"),
      "  ;",
    ];

    mixin += [
      // "  ${fieldType.name} get ${field.name};",
      "}",
    ];

    fieldsToProcess.forEach((fld) {
      /// First letter is underscore
      final concreteName = "${fld.elementName.capitalize()}Route";

      final parsed = RouteDefinition.from(fld.reader);
      if (parsed.widgetType != null) {
        /// This is a widget route
        mixin += [
          "class $concreteName extends UriTemplateAppPageRoute<${parsed.returns ?? 'dynamic'}, ${concreteName}Params> {",
          "",
          """
          $concreteName()
            : super.ofUri(
                "${parsed.uri ?? "/${fld.elementName}"}",
                (context, ${concreteName}Params p) => ${parsed.widgetType.safeName}(),
                (dyn) => ${concreteName}Params(),
                name: "${parsed.name ?? fld.elementName.capitalize()}",
              );
              
          """,
        ];

        mixin += ["}"];

        mixin += [
          "",
          "",
          "class ${concreteName}Params extends DefaultRouteParams {",
        ];

        mixin += ["}"];
      } else {
        /// This is a completable route

        /// This is a widget route
        var ft = (parsed.handler.type as FunctionType);
        var fel = ft.element as FunctionElement;
        mixin += [
          """
          class $concreteName extends UriTemplateCompletableAppRoute<${parsed.returns.safeName ?? 'dynamic'}, RouteParams> {
            $concreteName(): super(
               "${parsed.uri ?? "/${fld.elementName}"}",
                  (context, ${concreteName}Params p, sendRoute) => ${ft.element.name}(),
                  (dyn) => ${concreteName}Params(),
                  name: "${parsed.name ?? fld.elementName.capitalize()}",
            );
            
            AppRouteMatch<${parsed.returns.safeName ?? 'dynamic'}, dynamic> ${fel.name}(${delegateFunctionDef(ft)}) {
              return ${delegateFunction(ft, fel.name)};
            }
          }
          
          class ${concreteName}Params extends DefaultRouteParams {
          
          }
          """
        ];
      }
      return mixin.join("\n");
    });
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

extension AnnotatedNameExt<T> on Annotated<T> {
  String get elementName {
    return fieldName(element);
  }
}

class RouteDefinition {
  final String uri;
  final DartType widgetType;
  final DartType returns;
  final String ctor;
  final DartObject handler;
  final DartType params;
  final String name;

  const RouteDefinition({
    @required this.uri,
    @required this.widgetType,
    @required this.returns,
    @required this.ctor,
    @required this.handler,
    @required this.params,
    @required this.name,
  }) : assert(handler != null || widgetType != null,
            "You must have either handler or widgetType set on the annotation");

  factory RouteDefinition.from(ConstantReader annotation) {
    return RouteDefinition(
        uri: annotation.get("uri"),
        widgetType: annotation.get("widgetType"),
        returns: annotation.get("returns"),
        ctor: annotation.get("ctor"),
        handler: annotation.get("handler"),
        params: annotation.get("params"),
        name: annotation.get("name"));
  }
}

extension ConstantReaderNullSafeExt on ConstantReader {
  T get<T>(String field) {
    final v = read(field);
    if (v == null) return null;
    if (v.isNull) {
      return null;
    } else if (v.isLiteral) {
      return v.literalValue as T;
    } else if (v.isList) {
      return v.listValue as T;
    } else if (v.isType) {
      return v.typeValue as T;
    } else if (v.isSet) {
      return v.setValue as T;
    } else if (v.isNull) {
      return null;
    } else {
      return v.objectValue as T;
    }
  }
}

extension DartTypeName on DartType {
  String get safeName {
    return getDisplayString(withNullability: false);
  }
}

String delegateFunction(FunctionType method, String delegateName) {
  var str = "$delegateName(";
  for (final p in method.parameters) {
    str += "${p.passthrough}, ";
  }
  str = str.substring(0, str.length - 1);
  str += ");";
  return str;
}

String delegateFunctionDef(FunctionType method) {
  var str = "";
  bool hitPositional = false;
  for (final p in method.parameters) {
    if (p.isNamed && !hitPositional) {
      str += "{";
      hitPositional = true;
    } else if (!p.isNamed && hitPositional) {
      hitPositional = false;
      str += "},";
    }
    str += "${p.redeclare},";
  }
  if (hitPositional) {
    str += "}";
  } else {
    str = str.substring(0, str.length - 1);
  }
  return str;
}
