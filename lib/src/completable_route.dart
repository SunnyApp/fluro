import 'dart:async';

import 'package:flutter/widgets.dart';

typedef Future<T> FutureCallback<T>(BuildContext context);

/// Converts a plain future to a route.  When this route is pushed, it makes a call back to the invoker, passing
/// the [BuildContext].  When that future is completed, this route is automatically popped.
///
/// ```
/// CompletableRouteAdapter<Contact>((context) async => loadFromServer(context, "id"));
/// ```
///
/// This class is useful in cases where you want to push something to the [Navigator], but there's no Widget to be
/// displayed, like displaying a modal.
class CompletableRouteAdapter<R> extends Route<R> {
  final FutureCallback<R> invoker;

  /// The completer to fire when this route is popped;
  CompletableRouteAdapter(this.invoker);

  @override
  TickerFuture didPush() {
    final tf = super.didPush();
    tf.whenComplete(() async {
      try {
        final result = await invoker(this.navigator!.context);
        await Future.microtask(() {
          this.navigator!.pop(result);
        });
      } catch (e) {
        await Future.microtask(() {
          this.navigator!.pop();
        });
      }
    });
    return tf;
  }
}
