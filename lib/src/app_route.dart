import 'dart:async';

import 'package:flutter/widgets.dart';

import 'common.dart';

/// Base class for app routes.  See [AppPageRoute] and [CompletableAppRoute]
abstract class AppRoute<R, P extends RouteParams> {
  /// The route template string
  String get route;

  /// Function for creating route uris
  ToRouteUri? get toRouteUri;

  /// Function to convert parameters to the type expected by this route
  ParameterConverter<P>? get paramConverter;

  String? routeTitle([P? params]);

  String? routeUri(params);

  String? get name;
}

/// An app route:
///
/// Has a path
/// Has a handler callback
/// Knows how to convert raw map params into actual params
/// Has a default transition type
class AppPageRoute<R, P extends RouteParams>
    implements AppRoute<R, P>, InternalArgs {
  @override
  final String route;

  @override
  final String? name;
  final WidgetHandler<R, P?>? _handler;
  @override
  final ParameterConverter<P>? paramConverter;
  final ToRouteTitle<P>? _toRouteTitle;

  @override
  final ToRouteUri? toRouteUri;
  final TransitionType? transitionType;

  AppPageRoute(
    this.route,
    WidgetHandler<R, P?>? handler,
    this.paramConverter, {
    this.name,
    this.transitionType,
    this.toRouteUri,
    ToRouteTitle<P>? toRouteTitle,
  })  : _handler = handler,
        _toRouteTitle = toRouteTitle;

  Widget handleAny(BuildContext context, input) {
    return _handler!(context, input as P?);
  }

  Widget handle(BuildContext context, P input) {
    return _handler!(context, input);
  }

  @override
  String? routeTitle([params]) {
    if (_toRouteTitle == null) return null;
    final p = paramConverter?.call(params) ?? params;
    return _toRouteTitle!(p);
  }

  @override
  String routeUri(params) {
    if (toRouteUri == null && (params == null || params is InternalArgs))
      return route;
    assert(
        this.toRouteUri != null,
        "You must either use a simple route, or have a way of "
        "constructing a reverse URI.  If the parameters don't affect the URL, you can mark "
        "the args with InternalArgs to avoid this error.\n\t Route=$route, params=$params");

    return toRouteUri!(RouteParams.of(params));
  }

  @override
  String toString() {
    return 'AppPageRoute{route: $route, name: $name}';
  }
}

abstract class InternalArgs {}

/// The details of the route are opaque, all the transitions are managed internally
/// and a future is returned.
class CompletableAppRoute<R, P extends RouteParams> implements AppRoute<R, P> {
  /// The uri or name of hte route
  @override
  final String route;

  /// The friendly name of the route
  @override
  final String? name;

  /// Callback when the route is invoked
  final CompletableHandler<R, P> _handler;

  /// Used to convert to typed parameters
  @override
  final ParameterConverter<P> paramConverter;

  /// Extracts a detailed title from the route
  final ToRouteTitle<P>? _toRouteTitle;

  /// Builds a route uri for given parameters
  @override
  final ToRouteUri? toRouteUri;

  CompletableAppRoute(
    this.route,
    CompletableHandler<R, P> handler,
    this.paramConverter, {
    this.name,
    this.toRouteUri,
    ToRouteTitle<P>? toRouteTitle,
  })  : _handler = handler,
        _toRouteTitle = toRouteTitle;

  Future<R> handle(BuildContext context, P? params, SendRoute sender) {
    return _handler(context, params, sender);
  }

  Future handleAny(BuildContext context, params, SendRoute sender) {
    return _handler(context, params as P, sender);
  }

  @override
  String? routeTitle([params]) {
    if (_toRouteTitle == null) return null;
    final p = paramConverter(params);
    return _toRouteTitle!(p);
  }

  @override
  String? routeUri(params) {
    if (toRouteUri == null) return null;
    return toRouteUri!(RouteParams.of(params));
  }

  @override
  String toString() {
    return 'CompletableAppRoute{route: $route, name: $name}';
  }
}
