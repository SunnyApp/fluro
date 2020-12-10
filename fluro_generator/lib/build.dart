import 'package:build/build.dart';
import 'package:fluro_generator/route_params_generator.dart';
import 'package:source_gen/source_gen.dart';

Builder fluroBuilder(BuilderOptions options) =>
    SharedPartBuilder([RouteParamsGenerator()], 'fluro');
