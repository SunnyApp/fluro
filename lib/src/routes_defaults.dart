import 'dart:io';

import 'package:fluro/fluro.dart';
import 'package:fluro/src/common.dart';
import 'package:fluro/src/completable_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_route.dart';

class DefaultRouterFactory implements RouterFactory {
  RouteCreator<R, P> generate<R, P extends RouteParams>(
    AppRoute<R, P> appRoute,
    TransitionType transition,
    Duration transitionDuration,
    RouteTransitionsBuilder transitionsBuilder,
  ) {
    return (String routeName, P parameters) {
      final routeSettings = RouteSettings(name: routeName, arguments: parameters);
      if (appRoute is CompletableAppRoute<R, P>) {
        return CompletableRouteAdapter<R>((context) {
          return appRoute.handleAny(context, parameters).then((_) => _ as R);
        });
      } else if (appRoute is AppPageRoute<R, P>) {
        bool isNativeTransition = (transition == TransitionType.native || transition == TransitionType.nativeModal);

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
        } else if (transition == TransitionType.material || transition == TransitionType.materialFullScreenDialog) {
          return MaterialPageRoute<R>(
              settings: routeSettings,
              fullscreenDialog: transition == TransitionType.materialFullScreenDialog,
              builder: (BuildContext context) {
                return appRoute.handleAny(context, parameters);
              });
        } else if (transition == TransitionType.cupertino || transition == TransitionType.cupertinoFullScreenDialog) {
          return CupertinoPageRoute<R>(
              settings: routeSettings,
              fullscreenDialog: transition == TransitionType.cupertinoFullScreenDialog,
              builder: (BuildContext context) {
                return appRoute.handleAny(context, parameters);
              });
        } else {
          final routeTransitionsBuilder =
              transition == TransitionType.custom ? transitionsBuilder : standardTransitionsBuilder(transition);

          return PageRouteBuilder<R>(
            settings: routeSettings,
            pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
              try {
                return appRoute.handleAny(context, parameters);
              } catch (e, stack) {
                print(e);
                print(stack);
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

  const DefaultRouterFactory();
}

RouteTransitionsBuilder standardTransitionsBuilder(TransitionType transitionType) {
  return (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
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
