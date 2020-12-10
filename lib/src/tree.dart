/*
 * fluro
 * Created by Yakka
 * https://theyakka.com
 * 
 * Copyright (c) 2019 Yakka, LLC. All rights reserved.
 * See LICENSE for distribution and usage details.
 */

import 'package:fluro/src/common.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

import 'app_route.dart';

enum RouteTreeNodeType {
  component,
  parameter,
}

final _log = Logger("appRoute");

const missingRouteName = "/missing";

class AppRouteMatch {
  // constructors
  AppRouteMatch(this.route, Map<String, dynamic> rawParams)
      : parameters =
            route.paramConverter?.call(rawParams) ?? RouteParams.of(rawParams);

  AppRouteMatch.missing()
      : route = null,
        parameters = RouteParams.empty();

  bool get isMissing => route == null;

  // properties
  final AppRoute route;
  final RouteParams parameters;

  @override
  String toString() {
    return isMissing
        ? "AppRouteMatch:{missing=true; parameters=$parameters}"
        : "AppRouteMatch:{route:$route; parameters=$parameters}";
  }

  AppRouteMatch.builder(String route,
      {@required WidgetBuilder builder, String name})
      : parameters = null,
        route = AppPageRoute(route, (c, _) => builder(c), (_) => null,
            name: name, toRouteUri: (_) => route);
}

Map<String, dynamic> sanitizeParams(Map<String, dynamic> params) {
  if (params == null) return {};
  return {
    for (final entry in (params.entries))
      if (entry.value is List && (entry.value as List).length == 1)
        entry.key: (entry.value as List).first
      else if (entry.value is List && (entry.value as List).isNotEmpty)
        entry.key: entry.value
      else if (entry.value is! List)
        entry.key: entry.value,
  };
}

class RouteTreeNodeMatch {
  // constructors
  RouteTreeNodeMatch(this.node) : _parameters = <String, dynamic>{};

  RouteTreeNodeMatch.fromMatch(RouteTreeNodeMatch match, this.node)
      : _parameters = <String, dynamic>{} {
    // ignore: unused_local_variable
    var self = this;
    if (match != null) {
      self += match._parameters;
    }
  }

  RouteTreeNodeMatch operator +(Map<String, dynamic> values) {
    values?.forEach((k, v) {
      this[k] = v;
    });
    return this;
  }

  void operator []=(key, value) {
    String _key = "$key";
    final existing = _parameters[key];
    if (existing == null) {
      _parameters[_key] = value;
    } else if (existing is Iterable) {
      _parameters[_key] = {
        ...existing,
        if (value is Iterable) ...value else value
      };
    } else {
      _parameters[_key] = {
        existing,
        if (value is Iterable) ...value else value
      };
    }
  }

  // properties
  final RouteTreeNode node;
  final Map<String, dynamic> _parameters;

  @override
  String toString() {
    return '${node.path}: ${_parameters.entries.map((e) => "${e.key}=${e.value}").join("; ")}';
  }
}

class RouteTreeNode {
  // constructors
  RouteTreeNode(
    this.part,
    this.type, {
    this.parent,
    List<AppRoute> routes,
    List<RouteTreeNode> nodes,
  })  : routes = routes ?? [],
        nodes = nodes ?? [];

  // properties
  final String part;
  final RouteTreeNodeType type;
  final List<AppRoute> routes;
  final List<RouteTreeNode> nodes;
  final RouteTreeNode parent;

  bool isParameter() => type == RouteTreeNodeType.parameter;
}

class RouteTree {
  // private
  final List<RouteTreeNode> _nodes = <RouteTreeNode>[];
  bool _hasDefaultRoute = false;
  final Map<String, AppRoute> _routesByKey = {};
  final ParameterExtractorType parameterType;

  RouteTree(this.parameterType);

  AppRoute findRouteByKey(String key) {
    return _routesByKey[key];
  }

  // addRoute - add a route to the route tree
  AppRoute<R, P> addRoute<R, P extends RouteParams>(AppRoute<R, P> route) {
    if (_routesByKey.containsKey(route.route)) {
      _log.info("DUPLICATE ROUTE: ${route.route}");
    }
    _routesByKey[route.route] = route;
    String path = route.route;
    // is root/default route, just add it
    if (path == Navigator.defaultRouteName) {
      if (_hasDefaultRoute) {
        // throw an error because the internal consistency of the router
        // could be affected
        throw ("Default route was already defined");
      }
      var node =
          RouteTreeNode(path, RouteTreeNodeType.component, routes: [route]);
      _nodes.add(node);
      _hasDefaultRoute = true;
      return route;
    }
    if (path.startsWith("/")) {
      path = path.substring(1);
    }
    final pathComponents = path.split('/');
    RouteTreeNode parent;
    for (int i = 0; i < pathComponents.length; i++) {
      String component = pathComponents[i];
      final node = _nodeForComponent(component, parent) ??
          RouteTreeNode(component, _typeForComponent(component),
              parent: parent);
      if (parent == null) {
        _nodes.add(node);
      } else {
        parent.nodes.add(node);
      }

      if (i == pathComponents.length - 1) {
        node.routes.add(route);
      }
      parent = node;
    }
    return route;
  }

  AppRouteMatch matchRoute(String path) {
    if (path == null) return null;
    final uri = Uri.parse(path);
    final components =
        path == Navigator.defaultRouteName ? const ["/"] : uri.pathSegments;

    var nodeMatches = <RouteTreeNode, RouteTreeNodeMatch>{};
    var nodesToCheck = _nodes;
    RouteTreeNodeMatch match;
    for (final segment in components) {
      final currentMatches = <RouteTreeNode, RouteTreeNodeMatch>{};
      final nextNodes = <RouteTreeNode>[];
      for (final node in nodesToCheck) {
        bool isMatch = (node.part == segment || node.isParameter());
        if (isMatch) {
          final parentMatch = nodeMatches[node.parent];
          match = RouteTreeNodeMatch.fromMatch(parentMatch, node);
          if (node.isParameter()) {
            String paramKey = parameterType.extractName(node.part);
            match[paramKey] = segment;
          }

//          print("matched: ${node.part}, isParam: ${node.isParameter()}, params: ${match.parameters}");
          currentMatches[node] = match;
          nextNodes.addAll(node.nodes);
        }
      }

      nodeMatches = currentMatches;
      nodesToCheck = nextNodes;
      if (currentMatches.values.isEmpty) {
        return null;
      }
    }
    if (match != null && uri.queryParametersAll != null) {
      match += uri.queryParametersAll;
    }
    List<RouteTreeNodeMatch> matches =
        nodeMatches.values.where((_) => _ != null).toList();
    for (final match in matches) {
      RouteTreeNode nodeToUse = match.node;
      _log.fine(
          "using match: $match, ${nodeToUse?.part}, ${match?._parameters}");
      if (nodeToUse != null &&
          nodeToUse.routes != null &&
          nodeToUse.routes.isNotEmpty) {
        final routes = nodeToUse.routes;
        final routeMatch =
            AppRouteMatch(routes[0], sanitizeParams(match._parameters));
        return routeMatch;
      }
    }
    return null;
  }

  String printTree({bool logToConsole = true}) {
    final _ = _printSubTree();
    if (logToConsole) print(_);
    return _;
  }

  String _printSubTree({RouteTreeNode parent, int level = 0}) {
    var str = "";
    List<RouteTreeNode> nodes = parent != null ? parent.nodes : _nodes;
    for (RouteTreeNode node in nodes) {
      String indent = "";
      for (int i = 0; i < level; i++) {
        indent += "    ";
      }
      str += "$indent${node.part}: total routes=${node.routes.length}\n";
      if (node.nodes != null && node.nodes.isNotEmpty) {
        str += "${_printSubTree(parent: node, level: level + 1)}\n";
      }
    }
    return str;
  }

  RouteTreeNode _nodeForComponent(String component, RouteTreeNode parent) {
    List<RouteTreeNode> nodes = _nodes;
    if (parent != null) {
      // search parent for sub-node matches
      nodes = parent.nodes;
    }
    for (RouteTreeNode node in nodes) {
      if (node.part == component) {
        return node;
      }
    }
    return null;
  }

  RouteTreeNodeType _typeForComponent(String component) {
    RouteTreeNodeType type = RouteTreeNodeType.component;
    if (parameterType.isParameter(component)) {
      type = RouteTreeNodeType.parameter;
    }
    return type;
  }
}

extension StringPathExt on String {
  String toPath() {
    final self = this ?? "/";
    return self.startsWith("/") ? self : "/$self";
  }
}

extension RouteTreeNodePathExt on RouteTreeNode {
  String get path {
    return "${parent?.path ?? ''}${part?.toPath() ?? ''}";
  }

  List<String> get paths {
    return <String>{
      path,
      for (final child in (nodes ?? <RouteTreeNode>[])) ...child.paths,
    }.toList();
  }
}

extension RouteTreePathExt on RouteTree {
  List<String> get paths {
    return <String>{
      for (final node in _nodes) ...node.paths,
    }.toList();
  }
}
