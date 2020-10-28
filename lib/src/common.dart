/*
 * fluro
 * Created by Yakka
 * https://theyakka.com
 * 
 * Copyright (c) 2019 Yakka, LLC. All rights reserved.
 * See LICENSE for distribution and usage details.
 */

import 'dart:async';

import 'package:flutter/widgets.dart';

import 'app_route.dart';

///
typedef Route<T> RouteCreator<T, P extends RouteParams>(
    String name, P parameters);

typedef Future<R> RouteExecutor<R>();

/// Retrieves the navigator state for this router
typedef NavigatorState NavigatorOf(BuildContext context, bool useRootNavigator);

/// This class is responsible for providing a [RouteCreator] for a static [AppRoute].  You would use this if you want/
/// need to fully customize the `Route`, or if you use a specialized `Route` subclass.
abstract class RouterFactory {
  RouteCreator<R, P> generate<R, P extends RouteParams>(
    AppRoute<R, P> appRoute,
    TransitionType transition,
    Duration transitionDuration,
    RouteTransitionsBuilder transitionsBuilder,
  );

  RouteCreator generateAny(
    AppRoute appRoute,
    TransitionType transition,
    Duration transitionDuration,
    RouteTransitionsBuilder transitionsBuilder,
  );
}

/// Used as a higher-order routing function, that dispatches the route immediately
typedef Future SendRoute(
    BuildContext context, AppRoute newRoute, RouteParams params);

/// Used by [CompletableAppRoute]
typedef Future<R> CompletableHandler<R, P extends RouteParams>(
    BuildContext context, P parameters, SendRoute sendRoute);

/// Used by [AppPageRoute] Creates a widget, given [P] parameters
typedef Widget WidgetHandler<R, P>(BuildContext context, P parameters);

/// Converts dynamic map arguments to a known type [P]
typedef P ParameterConverter<P extends RouteParams>(rawInput);

/// Given parameters, produces a link back to this route
typedef String ToRouteUri(parameters);

/// Given parameters, produces a title for this route
typedef String ToRouteTitle<P>(P parameters);

abstract class RouteParams {
  Map<String, dynamic> toMap();

  factory RouteParams.of(map) {
    map ??= DefaultRouteParams();
    if (map is Map<String, dynamic>) {
      return DefaultRouteParams(map);
    } else if (map is RouteParams) {
      return map;
    } else {
      throw "Illegal param type ${map?.runtimeType}";
    }
  }

  factory RouteParams.ofId(String id) {
    assert(id != null);
    return DefaultRouteParams({"id": id});
  }

  dynamic operator [](String key);

  factory RouteParams.empty() => DefaultRouteParams();
}

class DefaultRouteParams implements RouteParams {
  final Map<String, dynamic> params;

  const DefaultRouteParams([Map<String, dynamic> params])
      : params = params ?? const <String, dynamic>{};

  @override
  Map<String, dynamic> toMap() {
    return params;
  }

  @override
  operator [](String key) {
    return params[key];
  }
}

enum TransitionType {
  native,
  nativeModal,
  inFromLeft,
  inFromRight,
  inFromBottom,
  fadeIn,
  custom, // if using custom then you must also provide a transition
  material,
  materialFullScreenDialog,
  cupertino,
  cupertinoFullScreenDialog,
}

class RouteNotFoundException implements Exception {
  final String message;
  final String path;

  RouteNotFoundException(this.message, this.path);

  @override
  String toString() {
    return "No registered route was found to handle '$path'";
  }
}

extension AppRouteCastingExtensions<R, P extends RouteParams>
    on AppRoute<R, P> {
  AppPageRoute<R, P> asPageRoute() => this as AppPageRoute<R, P>;

  CompletableAppRoute<R, P> asCompletableRoute() =>
      this as CompletableAppRoute<R, P>;
}

/// How path parameters are extracted
enum ParameterExtractorType {
  /// Uses uris based on the RFC 6570 spec.
  /// https://tools.ietf.org/html/rfc6570
  ///
  /// Path values are specified using curly braces, eg:
  /// `/contacts/{id}`
  uriTemplate,

  /// URI path attributes specified by prefixing the variable name with a colon:
  /// `/contacts/:id`
  restTemplate
}

extension ParameterExtractorTypeExtensions on ParameterExtractorType {
  bool isParameter(String input) {
    if (input == null || input == "") return false;
    if (this == null) return false;
    switch (this) {
      case ParameterExtractorType.uriTemplate:
        return input.startsWith("{") && input.endsWith("}");
      case ParameterExtractorType.restTemplate:
        return input.startsWith(":");
      default:
        return false;
    }
  }

  /// Extracts the parameter name from a path components
  String extractName(String pathComponent) {
    if (!this.isParameter(pathComponent)) {
      throw InvalidRouteDefinition(code: "invalidComponentFormat");
    }
    switch (this) {
      case ParameterExtractorType.uriTemplate:
        return pathComponent.substring(1, pathComponent.length - 1);
      case ParameterExtractorType.restTemplate:
        return pathComponent.substring(1);
      default:
        return null;
    }
  }
}

class InvalidRouteDefinition {
  final String message;
  final String route;
  final String code;

  InvalidRouteDefinition({this.code, this.message, this.route});
}

extension RouteParamsExt on RouteParams {
  T get<T>(key) {
    return this["$key"] as T;
  }
}

SendRoute get noopSendRoute {
  return (_, __, ___) async {};
}
