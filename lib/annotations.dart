// ignore: camel_case_types
import 'package:sunny_dart/helpers.dart';

class routeParams {
  final String routeUri;

  const routeParams([this.routeUri]);
}

// ignore: camel_case_types
class pathParam {
  const pathParam();
}

class routes {
  const routes();
}

class route {
  final String uri;
  final Type widgetType;
  final Type returns;
  final String ctor;
  final Function handler;
  final Type params;
  final String name;

  const route.widget(this.widgetType,
      {this.returns, this.ctor = "", this.name, this.uri})
      : handler = null,
        params = null;

  const route.function(this.handler,
      {this.returns, this.params, this.name, this.uri})
      : widgetType = null,
        ctor = null;
}

typedef ValueReader = dynamic Function(String name);
