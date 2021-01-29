/*
 * fluro
 * Created by Yakka
 * https://theyakka.com
 * 
 * Copyright (c) 2019 Yakka, LLC. All rights reserved.
 * See LICENSE for distribution and usage details.
 */
import 'package:sunny_fluro/sunny_fluro.dart';
import 'package:router_example/config/route_handlers.dart';

class Routes {
  static Routes instance;
  final FRouter router;
  static const String root = '/';
  static const String demoSimple = '/demo';
  static const String demoSimpleFixedTrans = '/demo/fixedtrans';
  static const String demoFunc = '/demo/func';
  static const String deepLink = '/message';

  final AppRoute rootRoute;
  final AppRoute demoSimpleRoute;
  final AppRoute demoSimpleFixedTransRoute;
  final AppRoute demoFuncRoute;
  final AppRoute deepLinkRoute;

  Routes(this.router)
      : rootRoute = router.define(root, handler: rootHandler),
        demoSimpleRoute = router.define(demoSimple, handler: demoRouteHandler),
        demoSimpleFixedTransRoute = router.define(demoSimpleFixedTrans,
            handler: demoRouteHandler,
            transitionType: TransitionType.inFromLeft),
        demoFuncRoute =
            router.defineCompletable(demoFunc, handler: demoFunctionHandler),
        deepLinkRoute = router.define(deepLink, handler: deepLinkHandler);
}
