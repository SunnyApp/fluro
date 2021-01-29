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

  /// Casts this route to the expected type.  If the cast is invalid, you
  /// may have errors when running the functions because parameters are
  /// not cast correctly
  AppRoute<RR, PP> cast<RR, PP extends RouteParams>();
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
  final String name;
  final WidgetHandler<R, P> _handler;
  @override
  final ParameterConverter<P> paramConverter;
  final ToRouteTitle<P> _toRouteTitle;

  @override
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
    if (toRouteUri == null && (params == null || params is InternalArgs))
      return route;
    assert(
        this.toRouteUri != null,
        "You must either use a simple route, or have a way of "
        "constructing a reverse URI.  If the parameters don't affect the URL, you can mark "
        "the args with InternalArgs to avoid this error.\n\t Route=$route, params=$params");

    return toRouteUri(RouteParams.of(params));
  }

  @override
  String toString() {
    return 'AppPageRoute{route: $route, name: $name}';
  }

  @override
  AppRoute<RR, PP> cast<RR, PP extends RouteParams>() {
    return AppPageRoute<RR, PP>(
      this.route,
      this._handler?.cast<RR, PP>(),
      this.paramConverter?.cast<PP>(),
      name: name,
      transitionType: transitionType,
      toRouteUri: toRouteUri,
      toRouteTitle: _toRouteTitle?.cast<PP>(),
    );
  }
}

abstract class InternalArgs {}

/// The details of the route are opaque, it manages everything internally
class CompletableAppRoute<R, P extends RouteParams> implements AppRoute<R, P> {
  @override
  final String route;
  @override
  final String name;
  final CompletableHandler<R, P> _handler;
  @override
  final ParameterConverter<P> paramConverter;
  final ToRouteTitle<P> _toRouteTitle;
  @override
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

  @override
  AppRoute<RR, PP> cast<RR, PP extends RouteParams>() {
    return CompletableAppRoute<RR, PP>(
      route,
      _handler?.cast(),
      paramConverter?.cast(),
      name: name,
      toRouteUri: toRouteUri,
      toRouteTitle: _toRouteTitle?.cast(),
    );
  }
}

extension WidgetHandlerCastExt<R, P> on WidgetHandler<R, P> {
  WidgetHandler<RR, PP> cast<RR, PP>() {
    final self = this;
    if (self == null) return null;
    if (self is WidgetHandler<RR, PP>) return self as WidgetHandler<RR, PP>;
    return (context, PP outer) {
      return self?.call(context, outer as P);
    };
  }
}

extension ParamConverterCastExt<P extends RouteParams>
    on ParameterConverter<P> {
  ParameterConverter<PP> cast<PP extends RouteParams>() {
    final self = this;
    if (self == null) return null;
    if (self is ParameterConverter<PP>) return self as ParameterConverter<PP>;
    return (dyn) {
      return self?.call(dyn) as PP;
    };
  }
}

extension ToRouteTitleCastExt<P extends RouteParams> on ToRouteTitle<P> {
  ToRouteTitle<PP> cast<PP extends RouteParams>() {
    final self = this;
    if (self == null) return null;
    if (self is ToRouteTitle<PP>) return self as ToRouteTitle<PP>;
    return (PP dyn) {
      return self?.call(dyn as P);
    };
  }
}

extension CompletableHandlerCastExt<R, P extends RouteParams>
    on CompletableHandler<R, P> {
  CompletableHandler<RR, PP> cast<RR, PP extends RouteParams>() {
    final self = this;
    if (self == null) return null;
    if (self is CompletableHandler<RR, PP>)
      return self as CompletableHandler<RR, PP>;
    return (context, PP params, SendRoute sendRoute) async {
      final res = await self?.call(context, params as P, sendRoute);
      return res as RR;
    };
  }
}
