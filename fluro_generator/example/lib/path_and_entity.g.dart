// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'path_and_entity.dart';

// **************************************************************************
// DelegateGenerator
// **************************************************************************

abstract class __PathAndEntityDelegate {
  _PathAndEntity get _params;
}

mixin __PathAndEntityMixin implements __PathAndEntityDelegate {
  String? get routeId => _params.routeId;
  Entity? get entity => _params.entity;
}

// **************************************************************************
// DegenGenerator
// **************************************************************************

class EntityPage extends _EntityPage with __PathAndEntityMixin {
  EntityPage({
    String? routeId,
    Entity? entity,
    Key? key,
  }) : super(
            PathAndEntity(
              routeId: routeId,
              entity: entity,
            ),
            key: key);
}

// **************************************************************************
// RouteParamsGenerator
// **************************************************************************

class PathAndEntity extends _PathAndEntity implements RouteParams {
  PathAndEntity({
    String? routeId,
    Entity? entity,
  }) : super(routeId: routeId, entity: entity);

  @override
  dynamic operator [](String key) {
    switch (key) {
      case "routeId":
        return routeId;
      case "entity":
        return entity;
      default:
        throw "No parameter of that name $key";
    }
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      "routeId": routeId,
      "entity": entity,
    };
  }

  static PathAndEntity? of(input) {
    if (input is PathAndEntity) return input;
    if (input == null) return null;
    return PathAndEntity(
      routeId: input["routeId"] as String?,
      entity: input["entity"] as Entity?,
    );
  }
}
