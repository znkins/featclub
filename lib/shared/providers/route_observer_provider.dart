import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Observer de routes branché sur `GoRouter.observers`.
/// Utilisé par les écrans qui veulent rafraîchir leurs données au retour
/// depuis un écran enfant (mixin `RouteAware` + `didPopNext`).
final appRouteObserverProvider = Provider<RouteObserver<ModalRoute<void>>>(
  (ref) => RouteObserver<ModalRoute<void>>(),
);
