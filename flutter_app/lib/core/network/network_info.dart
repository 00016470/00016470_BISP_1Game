import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:connectivity_plus/connectivity_plus.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get connectivityStream;
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;

  NetworkInfoImpl(this.connectivity);

  @override
  Future<bool> get isConnected async {
    // On web, connectivity_plus cannot reliably detect localhost connectivity.
    // Let the HTTP layer surface errors instead.
    if (kIsWeb) return true;
    final result = await connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  @override
  Stream<bool> get connectivityStream {
    if (kIsWeb) return Stream.value(true);
    return connectivity.onConnectivityChanged
        .map((result) => result != ConnectivityResult.none);
  }
}
