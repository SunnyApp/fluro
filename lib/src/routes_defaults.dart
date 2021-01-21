import 'dart:io';

import 'package:sunny_fluro/src/common.dart';
import 'package:sunny_fluro/src/completable_route.dart';
import 'package:sunny_fluro/src/path_route_settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'app_route.dart';

final _log = Logger("defaultRouterFactory");

class DefaultRouterFactory implements RouterFactory {
  @override
  RouteCreator<R, P> generate<R, P extends RouteParams>(
    AppRoute<R, P> appRoute,
    TransitionType transition,
    Duration transitionDuration,
    RouteTransitionsBuilder transitionsBuilder,
  ) {
    return (String routeName, P parameters) {
      if (appRoute is CompletableAppRoute<R, P>) {
        return CompletableRouteAdapter<R>((context) {
          return appRoute.handleAny(context, parameters,
              (context, route, params) {
            /// This block of code is passed down to the AppRoute, as a way to
            /// invoke a child route from the parent route's context
            final routeCreator = generateAny(route, TransitionType.native,
                Duration(milliseconds: 300), null);
            final r = routeCreator(route.routeTitle(params), params);
            return Navigator.of(context).push(r);
          }).then((_) => _ as R);
        });
      } else if (appRoute is AppPageRoute<R, P>) {
        bool isNativeTransition = (transition == TransitionType.native ||
            transition == TransitionType.nativeModal);
        final routeSettings = PathRouteSettings.ofAppRoute(
          appRoute,
          routeParams: parameters,
        );

        if (isNativeTransition) {
          if (!kIsWeb && Platform.isIOS) {
            return CupertinoPageRoute<R>(
                settings: routeSettings,
                fullscreenDialog: transition == TransitionType.nativeModal,
                builder: (BuildContext context) {
                  return appRoute.handleAny(context, parameters);
                });
          } else {
            return MaterialPageRoute<R>(
                settings: routeSettings,
                fullscreenDialog: transition == TransitionType.nativeModal,
                builder: (BuildContext context) {
                  return appRoute.handleAny(context, parameters);
                });
          }
        } else if (transition == TransitionType.material ||
            transition == TransitionType.materialFullScreenDialog) {
          return MaterialPageRoute<R>(
              settings: routeSettings,
              fullscreenDialog:
                  transition == TransitionType.materialFullScreenDialog,
              builder: (BuildContext context) {
                return appRoute.handleAny(context, parameters);
              });
        } else if (transition == TransitionType.cupertino ||
            transition == TransitionType.cupertinoFullScreenDialog) {
          return CupertinoPageRoute<R>(
              settings: routeSettings,
              fullscreenDialog:
                  transition == TransitionType.cupertinoFullScreenDialog,
              builder: (BuildContext context) {
                return appRoute.handleAny(context, parameters);
              });
        } else {
          final routeTransitionsBuilder = transition == TransitionType.custom
              ? transitionsBuilder
              : standardTransitionsBuilder(transition);

          return PageRouteBuilder<R>(
            settings: routeSettings,
            pageBuilder: (BuildContext context, Animation<double> animation,
                Animation<double> secondaryAnimation) {
              try {
                return appRoute.handleAny(context, parameters);
              } catch (e, stack) {
                _log.severe("Error creating page: $e", e, stack);
                return Text("Invalid");
              }
            },
            transitionDuration: transitionDuration,
            transitionsBuilder: routeTransitionsBuilder,
          );
        }
      } else {
        throw "Invalid type";
      }
    };
  }

  /// Generates a route from untyped input sources
  @override
  RouteCreator generateAny(
    AppRoute appRoute,
    TransitionType transition,
    Duration transitionDuration,
    RouteTransitionsBuilder transitionsBuilder,
  ) =>
      generate(appRoute, transition, transitionDuration, transitionsBuilder);

  const DefaultRouterFactory();
}

RouteTransitionsBuilder standardTransitionsBuilder(
    TransitionType transitionType) {
  return (BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    if (transitionType == TransitionType.fadeIn) {
      return FadeTransition(opacity: animation, child: child);
    } else {
      const Offset topLeft = Offset(0.0, 0.0);
      const Offset topRight = Offset(1.0, 0.0);
      const Offset bottomLeft = Offset(0.0, 1.0);
      Offset startOffset = bottomLeft;
      Offset endOffset = topLeft;
      if (transitionType == TransitionType.inFromLeft) {
        startOffset = const Offset(-1.0, 0.0);
        endOffset = topLeft;
      } else if (transitionType == TransitionType.inFromRight) {
        startOffset = topRight;
        endOffset = topLeft;
      }

      return SlideTransition(
        position: Tween<Offset>(
          begin: startOffset,
          end: endOffset,
        ).animate(animation),
        child: child,
      );
    }
  };
}
