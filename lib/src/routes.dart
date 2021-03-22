/*
 * fluro
 * Created by Yakka
 * https://theyakka.com
 * 
 * Copyright (c) 2019 Yakka, LLC. All rights reserved.
 * See LICENSE for distribution and usage details.
 */

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:sunny_fluro/src/common.dart';
import 'package:sunny_fluro/sunny_fluro.dart';

import 'app_route.dart';

export 'routes_defaults.dart';

final _log = Logger("routes");

class FRouter {
  static final routes = FRouter();

  /// Route
  /// The tree structure that stores the defined routes
  final RouteTree _routeTree;

  /// Produces a navigator given a [BuildContext].  Can be overridden to use a globalKey or some
  /// other navigator mechanism.
  NavigatorOf navigatorOf;

  /// Generic handler for when a route has not been defined
  final AppRoute? notFoundRoute;

  /// Converts an [AppRoute] and parameters into a [Route] that can be used with a navigator
  RouterFactory routeFactory;

  FRouter(
      {NavigatorOf? navigatorOf,
      this.routeFactory = const DefaultRouterFactory(),
      this.notFoundRoute,
      ParameterExtractorType parameterMode =
          ParameterExtractorType.restTemplate})
      : _routeTree = RouteTree(parameterMode),
        navigatorOf = navigatorOf ??
            ((context, rootNavigator) {
              return Navigator.of(context, rootNavigator: rootNavigator);
            }) {
    if (notFoundRoute != null) {
      this.register(notFoundRoute!);
    }
  }

  FRouter.ofUriTemplates({
    NavigatorOf? navigatorOf,
    this.notFoundRoute,
    this.routeFactory = const DefaultRouterFactory(),
  })  : _routeTree = RouteTree(ParameterExtractorType.uriTemplate),
        navigatorOf = navigatorOf ??
            ((context, rootNavigator) =>
                Navigator.of(context, rootNavigator: rootNavigator)) {
    if (notFoundRoute != null) {
      this.register(notFoundRoute!);
    }
  }

  List<String> get paths => _routeTree.paths;

  /// Registers a pre-built [AppRoute]
  AppRoute<R, P> register<R, P extends RouteParams>(AppRoute<R, P> route) {
    return _routeTree.addRoute<R, P>(route);
  }

  /// Creates an [AppPageRoute] definition whose arguments are [Map<String, dynamic>]
  AppRoute<R, RouteParams> define<R>(String routePath,
      {String? name,
      required WidgetHandler<R, RouteParams?>? handler,
      TransitionType? transitionType}) {
    return _routeTree.addRoute<R, RouteParams>(
      AppPageRoute(routePath, handler, (_) => RouteParams.of(_),
          name: name,
          transitionType: transitionType,
          toRouteUri: (settings) => routePath),
    );
  }

  /// Creates a [CompletableAppRoute] definition.
  AppRoute<R, RouteParams> defineCompletable<R>(String routePath,
      {String? name, required CompletableHandler<R, RouteParams> handler}) {
    return _routeTree.addRoute<R, RouteParams>(
      CompletableAppRoute(routePath, handler, (_) => RouteParams.of(_),
          name: name),
    );
  }

  /// Creates an [AppPageRoute] definition for the passed [WidgetHandler], using a custom parameter type
  AppRoute<R, P> defineWithParams<R, P extends RouteParams>(String routePath,
      {required WidgetHandler<R, P?> handler,
      String? name,
      required ParameterConverter<P> paramConverter,
      TransitionType? transitionType}) {
    return _routeTree.addRoute<R, P>(
      AppPageRoute<R, P>(routePath, handler, paramConverter,
          name: name, transitionType: transitionType),
    );
  }

  /// Finds a defined [AppRoute] for the path value, or null if none could be found
  AppRouteMatch? matchRoute(String? path) {
    return _routeTree.matchRoute(path);
  }

  /// Prints the route tree so you can analyze it.
  String printTree({bool logToConsole = true}) {
    return _routeTree.printTree(logToConsole: logToConsole);
  }
}

extension RouterExtensions on FRouter {
  /// This extension allows the router to be integrated into [Navigator], eg:
  /// ```onGenerateRoute: routes.onGenerateRoute```
  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    /// First, look up the route by its name.  This is a case where the route is invoked via pushNamed with the
    /// arguments in [settings]

    _log.info(
        "onGenerateRoute: ${settings.name} with arguments ${settings.arguments}");
    AppRoute? appRoute = _routeTree.findRouteByKey(settings.name);
    _log.info(" -> ${settings.name} found by key: ${appRoute != null}");
    dynamic arguments = settings.arguments;
    if (appRoute == null) {
      /// The parameters are embedded in the url
      _log.info(" -> Attempting to extract url parameters");
      var match = _routeTree.matchRoute(settings.name);
      _log.info(match == null
          ? " -> Match not found.  Falling back to /notFound"
          : " -> ${settings.name} extracted $match");

      match ??= AppRouteMatch(notFoundRoute!, null);
      appRoute = match.route;
      arguments ??= match.parameters;
    }

    /// Changed from generate to generateAny - figure this context doesn't care
    /// about type arguments anyway
    final Route<dynamic> Function(String, RouteParams?) creator =
        this.routeFactory.generateAny(appRoute!, null, null, null);
    final route = creator(appRoute.route, appRoute.paramConverter!(arguments));
    return route;
  }

  /// Navigates to the provided [path].  It's assumed that the path represents the full url, containing
  /// any parameters, which will be extracted before navigating.
  Future navigateTo(BuildContext context, String path,
      {bool replace = false,
      bool clearStack = false,
      TransitionType? transition,
      Duration transitionDuration = const Duration(milliseconds: 250),
      RouteTransitionsBuilder? transitionBuilder}) {
    final match = matchRoute(path);
    if (match?.route == null) {
      // do something
      throw "Route not found";
    } else {
      return navigateToDynamicRoute(context, match!.route,
          replace: replace,
          parameters: match.parameters,
          clearStack: clearStack,
          transition: transition,
          transitionDuration: transitionDuration,
          transitionBuilder: transitionBuilder);
    }
  }

  /// Navigates directly to a route instance, using the provided [parameters].
  Future<R?> navigateToRoute<R, P extends RouteParams>(
      BuildContext context, AppRoute<R, P> appRoute,
      {bool replace = false,
      P? parameters,
      bool clearStack = false,
      TransitionType? transition,
      bool rootNavigator = false,
      Duration transitionDuration = const Duration(milliseconds: 250),
      RouteTransitionsBuilder? transitionBuilder}) {
    if (appRoute is AppPageRoute<R, P>) {
      final Route<R?> Function(String, P?) routeCreator =
          routeFactory.generate<R, P>(
        appRoute,
        appRoute.transitionType,
        transitionDuration,
        transitionBuilder,
      );

      final navigator = navigatorOf(context, rootNavigator == true);

      final route = routeCreator(appRoute.route, parameters);
      return replace
          ? navigator.pushReplacement(route as Route<R>)
          : navigator.push(route as Route<R>);
    } else if (appRoute is CompletableAppRoute<R, P>) {
      return appRoute.handle(context, parameters,
          (BuildContext context, AppRoute route, RouteParams params) {
        return navigateToDynamicRoute(context, route, parameters: params);
      });
    } else {
      throw "Invalid route type ${appRoute.runtimeType}";
    }
  }

  ///
  Future navigateToDynamicRoute(BuildContext context, AppRoute? appRoute,
      {bool replace = false,
      RouteParams? parameters,
      bool clearStack = false,
      TransitionType? transition,
      bool rootNavigator = false,
      Duration transitionDuration = const Duration(milliseconds: 250),
      RouteTransitionsBuilder? transitionBuilder}) {
    if (appRoute is AppPageRoute) {
      final Route<dynamic> Function(String, RouteParams?) routeCreator =
          routeFactory.generate(
        appRoute,
        appRoute.transitionType,
        transitionDuration,
        transitionBuilder,
      );

      final route = routeCreator(appRoute.route, parameters);
      final navigator = navigatorOf(context, rootNavigator == true);

      return replace ? navigator.pushReplacement(route) : navigator.push(route);
    } else if (appRoute is CompletableAppRoute) {
      return appRoute.handleAny(context, parameters,
          (context, route, params) async {
        return await navigateToDynamicRoute(context, route, parameters: params);
      });
    } else {
      throw "Unsupported AppRoutes type ${appRoute?.runtimeType ?? 'null'}";
    }
  }
}
