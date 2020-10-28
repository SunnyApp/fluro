import 'dart:async';

import 'package:flutter/widgets.dart';

import 'common.dart';

/// Base class for app routes.  See [AppPageRoute] and [CompletableAppRoute]
abstract class AppRoute<R, P extends RouteParams> {
  /// The route template string
  String get route;

  /// Function for creating route uris
  ToRouteUri get toRouteUri;

  /// Function to convert parameters to the type expected by this route
  ParameterConverter<P> get paramConverter;

  String routeTitle(P params);

  String routeUri(params);
  String get name;
}

/// An app route:
///
/// Has a path
/// Has a handler callback
/// Knows how to convert raw map params into actual params
/// Has a default transition type
class AppPageRoute<R, P extends RouteParams> implements AppRoute<R, P> {
  final String route;
  final String name;
  final WidgetHandler<R, P> _handler;
  final ParameterConverter<P> paramConverter;
  final ToRouteTitle<P> _toRouteTitle;
  final ToRouteUri toRouteUri;
  final TransitionType transitionType;

  AppPageRoute(
    this.route,
    WidgetHandler<R, P> handler,
    this.paramConverter, {
    this.name,
    this.transitionType,
    this.toRouteUri,
    ToRouteTitle<P> toRouteTitle,
  })  : _handler = handler,
        _toRouteTitle = toRouteTitle;

  Widget handleAny(BuildContext context, input) {
    return _handler(context, input as P);
  }

  Widget handle(BuildContext context, P input) {
    return _handler(context, input);
  }

  @override
  String routeTitle(params) {
    if (_toRouteTitle == null) return null;
    final p = paramConverter?.call(params) ?? params;
    return _toRouteTitle(p);
  }

  @override
  String routeUri(params) {
    if (toRouteUri == null && params == null) return route;
    if (toRouteUri == null) return null;
    return toRouteUri(RouteParams.of(params));
  }

  @override
  String toString() {
    return 'AppPageRoute{route: $route, name: $name}';
  }
}

/// The details of the route are opaque, it manages everything internally
class CompletableAppRoute<R, P extends RouteParams> implements AppRoute<R, P> {
  final String route;
  final String name;
  final CompletableHandler<R, P> _handler;
  final ParameterConverter<P> paramConverter;
  final ToRouteTitle<P> _toRouteTitle;
  final ToRouteUri toRouteUri;

  CompletableAppRoute(
    this.route,
    CompletableHandler<R, P> handler,
    this.paramConverter, {
    this.name,
    this.toRouteUri,
    ToRouteTitle<P> toRouteTitle,
  })  : _handler = handler,
        _toRouteTitle = toRouteTitle;

  Future<R> handle(BuildContext context, P params, SendRoute sender) {
    return _handler(context, params, sender);
  }

  Future handleAny(BuildContext context, params, SendRoute sender) {
    return _handler(context, params as P, sender);
  }

  @override
  String routeTitle(params) {
    if (_toRouteTitle == null) return null;
    final p = paramConverter(params);
    return _toRouteTitle(p);
  }

  @override
  String routeUri(params) {
    if (toRouteUri == null) return null;
    return toRouteUri(RouteParams.of(params));
  }

  @override
  String toString() {
    return 'CompletableAppRoute{route: $route, name: $name}';
  }
}
