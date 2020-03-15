/*
 * fluro
 * Created by Yakka
 * https://theyakka.com
 * 
 * Copyright (c) 2019 Yakka, LLC. All rights reserved.
 * See LICENSE for distribution and usage details.
 */

import 'package:fluro/fluro.dart';
import 'package:fluro/src/common.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_route.dart';

export 'routes_defaults.dart';

class Router {
  static final routes = Router();

  /// Route
  /// The tree structure that stores the defined routes
  final RouteTree _routeTree;

  /// Generic handler for when a route has not been defined
  WidgetHandler notFoundHandler;

  /// Converts an [AppRoute] and parameters into a [Route] that can be used with a navigator
  RouterFactory routeFactory;

  Router(
      {this.routeFactory = const DefaultRouterFactory(),
      ParameterExtractorType parameterMode = ParameterExtractorType.restTemplate})
      : _routeTree = RouteTree(parameterMode);

  Router.ofUriTemplates({this.routeFactory = const DefaultRouterFactory()})
      : _routeTree = RouteTree(ParameterExtractorType.uriTemplate);

  /// Registers a pre-built [AppRoute]
  AppRoute<R, P> register<R, P>(AppRoute<R, P> route) {
    return _routeTree.addRoute<R, P>(route);
  }

  /// Creates an [AppPageRoute] definition whose arguments are [Map<String, dynamic>]
  AppRoute<R, Map<String, dynamic>> define<R>(String routePath,
      {@required WidgetHandler<R, Map<String, dynamic>> handler, TransitionType transitionType}) {
    return _routeTree.addRoute<R, Map<String, dynamic>>(
      AppPageRoute(routePath, handler, (_) => _ as Map<String, dynamic>, transitionType: transitionType),
    );
  }

  /// Creates a [CompletableAppRoute] definition.
  AppRoute<R, Map<String, dynamic>> defineCompletable<R>(String routePath,
      {@required CompletableHandler<R, Map<String, dynamic>> handler}) {
    return _routeTree.addRoute<R, Map<String, dynamic>>(
      CompletableAppRoute(routePath, handler, (_) => _ as Map<String, dynamic>),
    );
  }

  /// Creates an [AppPageRoute] definition for the passed [WidgetHandler], using a custom parameter type
  AppRoute<R, P> defineWithParams<R, P>(String routePath,
      {@required WidgetHandler<R, P> handler,
      @required ParameterConverter<P> paramConverter,
      TransitionType transitionType}) {
    return _routeTree.addRoute<R, P>(
      AppPageRoute<R, P>(routePath, handler, paramConverter, transitionType: transitionType),
    );
  }

  /// Finds a defined [AppRoute] for the path value, or null if none could be found
  AppRouteMatch matchRoute(String path) {
    return _routeTree.matchRoute(path);
  }

  /// Prints the route tree so you can analyze it.
  void printTree() {
    _routeTree.printTree();
  }
}

extension RouterExtensions on Router {
  /// This extension allows the router to be integrated into [Navigator], eg:
  /// ```onGenerateRoute: routes.onGenerateRoute```
  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    /// First, look up the route by its name.  This is a case where the route is invoked via pushNamed with the
    /// arguments in [settings]
    AppRoute appRoute = _routeTree.findRouteByKey(settings.name);
    dynamic arguments = settings.arguments;
    if (appRoute == null) {
      /// The parameters are embedded in the url, we can ignore
      final match = _routeTree.matchRoute(settings.name) ?? AppRouteMatch.missing();
      appRoute = match.route;
      arguments ??= match.parameters;
    }

    final creator = this.routeFactory.generate(appRoute, null, null, null);
    return creator(appRoute.route, arguments);
  }

  /// Navigates to the provided [path].  It's assumed that the path represents the full url, containing
  /// any parameters, which will be extracted before navigating.
  Future navigateTo(BuildContext context, String path,
      {bool replace = false,
      bool clearStack = false,
      TransitionType transition,
      Duration transitionDuration = const Duration(milliseconds: 250),
      RouteTransitionsBuilder transitionBuilder}) {
    final match = matchRoute(path);
    if (match.route == null) {
      // do something
      throw "Route not found";
    } else {
      return navigateToDynamicRoute(context, match.route,
          replace: replace,
          parameters: match.parameters,
          clearStack: clearStack,
          transition: transition,
          transitionDuration: transitionDuration,
          transitionBuilder: transitionBuilder);
    }
  }

  /// Navigates directly to a route instance, using the provided [parameters].
  Future<R> navigateToRoute<R, P>(BuildContext context, AppRoute<R, P> appRoute,
      {bool replace = false,
      P parameters,
      bool clearStack = false,
      TransitionType transition,
      Duration transitionDuration = const Duration(milliseconds: 250),
      RouteTransitionsBuilder transitionBuilder}) {
    if (appRoute is AppPageRoute<R, P>) {
      final routeCreator = routeFactory.generate<R, P>(
        appRoute,
        appRoute.transitionType,
        transitionDuration,
        transitionBuilder,
      );

      final route = routeCreator(appRoute.route, parameters);
      return replace ? Navigator.pushReplacement(context, route) : Navigator.push(context, route);
    } else if (appRoute is CompletableAppRoute<R, P>) {
      return appRoute.handle(context, parameters);
    } else {
      throw "Invalid route type ${appRoute?.runtimeType ?? 'null'}";
    }
  }

  ///
  Future navigateToDynamicRoute(BuildContext context, AppRoute appRoute,
      {bool replace = false,
      dynamic parameters,
      bool clearStack = false,
      TransitionType transition,
      Duration transitionDuration = const Duration(milliseconds: 250),
      RouteTransitionsBuilder transitionBuilder}) {
    if (appRoute is AppPageRoute) {
      final routeCreator = routeFactory.generate(
        appRoute,
        appRoute.transitionType,
        transitionDuration,
        transitionBuilder,
      );

      final route = routeCreator(appRoute.route, parameters);
      return replace ? Navigator.pushReplacement(context, route) : Navigator.push(context, route);
    } else if (appRoute is CompletableAppRoute) {
      return appRoute.handleAny(context, parameters);
    } else {
      throw "Unsupported AppRoutes type ${appRoute?.runtimeType ?? 'null'}";
    }
  }
}
