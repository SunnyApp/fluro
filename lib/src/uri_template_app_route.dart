import 'package:flutter/widgets.dart';
import 'package:uri/uri.dart';

import 'app_route.dart';
import 'common.dart';
import 'routes.dart';

class UriTemplateAppPageRoute<R, P extends RouteParams>
    extends AppPageRoute<R, P> {
  final UriTemplate uriTemplate;

  UriTemplateAppPageRoute(
    this.uriTemplate,
    WidgetHandler<R, P> handler,
    ParameterConverter<P> paramConverter, {
    @required String name,
    TransitionType transitionType,
    ToRouteTitle<P> toRouteTitle,
  }) : super(
          uriTemplate.template,
          handler,
          paramConverter,
          transitionType: transitionType,
          name: name,
          toRouteTitle: (params) => name ?? toRouteTitle?.call(params),
          toRouteUri: (params) {
            final rp = RouteParams.of(params ?? <String, dynamic>{});
            final map = rp.toMap();

            if (map.isNotEmpty) {
              return uriTemplate.expand(map);
            } else {
              return "$uriTemplate";
            }
          },
        );
}

class UriTemplateCompletableAppRoute<R, P extends RouteParams>
    extends CompletableAppRoute<R, P> {
  final UriTemplate uriTemplate;

  UriTemplateCompletableAppRoute(
    this.uriTemplate,
    CompletableHandler<R, P> handler,
    ParameterConverter<P> paramConverter, {
    String name,
    ToRouteTitle<P> toRouteTitle,
  }) : super(
          uriTemplate.template,
          handler,
          paramConverter,
          name: name,
          toRouteTitle: (params) => name ?? toRouteTitle?.call(params),
          toRouteUri: (params) {
            return uriTemplate.expand(RouteParams.of(params).toMap());
          },
        );
}

extension RouterBaseExtensions on FRouter {
  /// Creates an [AppPageRoute] definition whose arguments are [Map<String, dynamic>]
  UriTemplateAppPageRoute<R, P> page<R, P extends RouteParams>(
      String routePath, WidgetHandler<R, P> handler,
      {ParameterConverter<P> paramConverter,
      String name,
      ToRouteTitle<P> toRouteTitle,
      TransitionType transitionType}) {
    if (P == RouteParams || P == dynamic) {
      paramConverter ??= (args) => defaultConverter(args) as P;
    }
    final route = UriTemplateAppPageRoute<R, P>(
      UriTemplate(routePath),
      handler,
      paramConverter,
      name: name,
      toRouteTitle: toRouteTitle,
      transitionType: transitionType,
    );
    this.register(
      route,
    );
    return route;
  }

  /// Creates an [AppPageRoute] definition whose arguments are [Map<String, dynamic>]
  UriTemplateAppPageRoute<R, P> simplePage<R, P extends RouteParams>(
      String routePath, Widget handler(),
      {ParameterConverter<P> paramConverter,
      String name,
      ToRouteTitle<P> toRouteTitle,
      TransitionType transitionType}) {
    if (P == RouteParams || P == dynamic) {
      paramConverter ??= (args) => defaultConverter(args) as P;
    }
    final route = UriTemplateAppPageRoute<R, P>(
      UriTemplate(routePath),
      (_, __) => handler(),
      paramConverter,
      name: name,
      toRouteTitle: toRouteTitle,
      transitionType: transitionType,
    );
    this.register(
      route,
    );
    return route;
  }

  /// Creates an [AppPageRoute] definition whose arguments are [Map<String, dynamic>]
  UriTemplateAppPageRoute<R, P> modal<R, P extends RouteParams>(
    String routePath,
    WidgetHandler<R, P> handler, {
    ParameterConverter<P> paramConverter,
    String name,
    ToRouteTitle<P> toRouteTitle,
  }) {
    return page<R, P>(
      routePath,
      handler,
      paramConverter: paramConverter,
      transitionType: TransitionType.nativeModal,
      name: name,
      toRouteTitle: toRouteTitle,
    );
  }

  /// Creates an [AppPageRoute] definition whose arguments are [Map<String, dynamic>]
  AppRoute<R, RouteParams> function<R>(
    String routePath,
    CompletableHandler<R, RouteParams> handler, {
    String name,
    ToRouteTitle toRouteTitle,
  }) {
    final route = UriTemplateCompletableAppRoute<R, RouteParams>(
      UriTemplate(routePath),
      handler,
      (_) => RouteParams.of(_),
      name: name,
      toRouteTitle: toRouteTitle,
    );
    register(route);
    return route;
  }
}

final ParameterConverter<RouteParams> defaultConverter =
    (args) => RouteParams.of(args);
