import 'dart:async';

import 'package:flutter/widgets.dart';

import 'common.dart';

/// Base class for app routes.  See [AppPageRoute] and [CompletableAppRoute]
abstract class AppRoute<R, P> {
  /// The route template string
  String get route;

  /// Function for creating route uris
  ToRouteUri get toRouteUri;

  /// Function to convert parameters to the type expected by this route
  ParameterConverter<P> get paramConverter;

  String routeTitle(P params);
}

/// An app route:
///
/// Has a path
/// Has a handler callback
/// Knows how to convert raw map params into actual params
/// Has a default transition type
class AppPageRoute<R, P> implements AppRoute<R, P> {
  final String route;
  final WidgetHandler<R, P> _handler;
  final ParameterConverter<P> paramConverter;
  final ToRouteTitle<P> _toRouteTitle;
  final ToRouteUri toRouteUri;
  final TransitionType transitionType;

  AppPageRoute(
    this.route,
    WidgetHandler<R, P> handler,
    this.paramConverter, {
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
    final p = paramConverter(params);
    return _toRouteTitle(p);
  }
}

/// The details of the route are opaque, it manages everything internally
class CompletableAppRoute<R, P> implements AppRoute<R, P> {
  final String route;
  final CompletableHandler<R, P> _handler;
  final ParameterConverter<P> paramConverter;
  final ToRouteTitle<P> _toRouteTitle;
  final ToRouteUri toRouteUri;

  CompletableAppRoute(
    this.route,
    CompletableHandler<R, P> handler,
    this.paramConverter, {
    this.toRouteUri,
    ToRouteTitle<P> toRouteTitle,
  })  : _handler = handler,
        _toRouteTitle = toRouteTitle;

  Future<R> handle(BuildContext context, P params) {
    return _handler(context, params);
  }

  Future handleAny(BuildContext context, params) {
    return _handler(context, params as P);
  }

  @override
  String routeTitle(params) {
    if (_toRouteTitle == null) return null;
    final p = paramConverter(params);
    return _toRouteTitle(p);
  }
}
