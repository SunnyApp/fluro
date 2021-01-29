import 'package:build/build.dart';
import 'package:sunny_fluro_generator/fluro_generator.dart';
import 'package:sunny_fluro_generator/route_params_generator.dart';
import 'package:source_gen/source_gen.dart';
import 'package:sunny_fluro_generator/routes_generator.dart';

Builder fluroBuilder(BuilderOptions options) =>
    SharedPartBuilder([RouteParamsGenerator()], 'fluro');

Builder fluroRoutesBuilder(BuilderOptions options) =>
    SharedPartBuilder([RoutesGenerator()], 'routes');

Builder fluroRouteBuilder(BuilderOptions options) =>
    SharedPartBuilder([RouteGenerator()], 'route');
