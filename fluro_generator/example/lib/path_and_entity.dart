import 'package:fluro/fluro.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_degen/annotations.dart';

part 'path_and_entity.g.dart';

@routeParams()
abstract class _PathAndEntity {
  final String routeId;
  final Entity entity;

  _PathAndEntity({String routeId, this.entity})
      : assert(routeId != null || entity?.id != null, "Must provide id"),
        routeId = routeId ?? entity?.id;
}

@degen()
abstract class _EntityPage extends StatelessWidget implements _PathAndEntity {
  @delegate()
  final _PathAndEntity _params;

  const _EntityPage(@flatten("PathAndEntity") this._params, {Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(_params.routeId);
  }
}

class Entity {
  final String id;

  Entity(this.id);
}
