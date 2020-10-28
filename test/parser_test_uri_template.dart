/*
 * fluro
 * Created by Yakka
 * https://theyakka.com
 * 
 * Copyright (c) 2019 Yakka, LLC. All rights reserved.
 * See LICENSE for distribution and usage details.
 */

import 'package:fluro/fluro.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets("FRouter correctly parses named parameters",
      (WidgetTester tester) async {
    String path = "/users/1234";
    String route = "/users/{id}";
    FRouter router = FRouter.ofUriTemplates();
    router.define(route, handler: null);
    AppRouteMatch match = router.matchRoute(path);
    expect(
        match?.parameters,
        equals({
          "id": "1234",
        }));
  });

  testWidgets("FRouter correctly parses named parameters with query",
      (WidgetTester tester) async {
    String path = "/users/1234?name=luke";
    String route = "/users/{id}";
    FRouter router = FRouter.ofUriTemplates();
    router.define(route, handler: null);
    AppRouteMatch match = router.matchRoute(path);
    expect(
        match?.parameters,
        equals({
          "id": "1234",
          "name": "luke",
        }));
  });

  testWidgets("FRouter correctly parses query parameters",
      (WidgetTester tester) async {
    String path = "/users/create?name=luke&phrase=hello%20world&number=7";
    String route = "/users/create";
    FRouter router = FRouter.ofUriTemplates();
    router.define(route, handler: null);
    AppRouteMatch match = router.matchRoute(path);
    expect(
        match?.parameters,
        equals({
          "name": "luke",
          "phrase": "hello world",
          "number": "7",
        }));
  });

  testWidgets("FRouter correctly parses array parameters",
      (WidgetTester tester) async {
    String path =
        "/users/create?name=luke&phrase=hello%20world&number=7&number=10&number=13";
    String route = "/users/create";
    FRouter router = FRouter.ofUriTemplates();
    router.define(route, handler: null);
    AppRouteMatch match = router.matchRoute(path);
    expect(
        match?.parameters,
        equals({
          "name": "luke",
          "phrase": "hello world",
          "number": ["7", "10", "13"],
        }));
  });

  testWidgets("FRouter correctly parses array parameters",
      (WidgetTester tester) async {
    String path =
        "/users/create?name=luke&phrase=hello%20world&number=7&number=10&number=13";
    String route = "/users/create";
    FRouter router = FRouter.ofUriTemplates();
    router.define(route, handler: null);
    AppRouteMatch match = router.matchRoute(path);
    expect(
        match?.parameters,
        equals({
          "name": "luke",
          "phrase": "hello world",
          "number": ["7", "10", "13"],
        }));
  });

  testWidgets("FRouter correctly matches route and transition type",
      (WidgetTester tester) async {
    String path = "/users/1234";
    String route = "/users/{id}";
    FRouter router = FRouter.ofUriTemplates();
    router.define(route,
        handler: null, transitionType: TransitionType.inFromRight);
    AppRouteMatch match = router.matchRoute(path);
    expect(
        TransitionType.inFromRight, match.route.asPageRoute().transitionType);
  });
}
