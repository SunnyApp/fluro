import 'package:sunny_fluro/src/app_route.dart';
import 'package:sunny_fluro/src/common.dart';
import 'package:sunny_fluro/src/fluro_ext.dart';
import 'package:flutter/cupertino.dart';

final typeParameters = RegExp("<(.*)>");
final newLinesPattern = RegExp("\\n");

extension _FluroTypeExtensions on Type {
  String? get name => "$this"
      .trimAround("_")!
      .replaceAllMapped(
        typeParameters,
        (match) => "[${match.group(1).uncapitalize()}]",
      )
      .uncapitalize();

  String? get simpleName => _simpleNameOfType(this);
}

String? _simpleNameOfType(Type type) {
  return "$type".replaceAll(typeParameters, '').uncapitalize();
}

String? calculateRoute(final input) {
  String? str;
  if (input is Type) {
    str = input.simpleName;
  } else {
    str = "$input";
  }
  return !str!.startsWith("/") ? "/$str" : str;
}

/// A more advanced route settings that lets us provide more context when routing
class PathRouteSettings extends RouteSettings implements RouteInformation {
  final String? label;
  final String? route;
  final String? resolvedPath;
  final RouteParams? routeParams;

  /// Creates data used to construct routes.
  PathRouteSettings({
    required dynamic route,
    required this.label,
    this.resolvedPath,
    this.routeParams,
  })  : route = calculateRoute(route),
        super(
            name: resolvedPath ?? calculateRoute(route) ?? label,
            arguments: routeParams);

  factory PathRouteSettings.ofAppRoute(
    AppRoute appRoute, {
    RouteParams? routeParams,
  }) {
    final resolvedPath = appRoute.routeUri(routeParams);
    return PathRouteSettings(
      label: appRoute.name,
      routeParams: routeParams,
      resolvedPath: resolvedPath,
      route: appRoute.route,
    );
  }

  @override
  String toString() {
    String str = '${resolvedPath ?? route ?? label}: ';
    if (resolvedPath != null && route != null) {
      str += ', route=$route';
    }
    if (routeParams != null) {
      str += ', params=${routeParams.runtimeType}';
    }

    return str;
  }

  @override
  String? get location => resolvedPath ?? route;

  @override
  PathRouteSettings get state => this;

  Map<String, dynamic> toJson() {
    // ignore: unnecessary_cast
    return {
      'label': this.label,
      'route': this.route,
      'resolvedPath': this.resolvedPath,
      'routeParams': this.routeParams?.toMap(),
    } as Map<String, dynamic>;
  }
}
