import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:connectivity_plus/connectivity_plus.dart';

/// Abstract interface for network connectivity information.
/// Provides methods to check current connectivity and listen for changes.
abstract class NetworkInfo {
  /// Returns true if the device has network connectivity.
  Future<bool> get isConnected;

  /// Stream that emits connectivity status changes.
  /// Emits true when connected, false when disconnected.
  Stream<bool> get connectivityStream;
}

/// Implementation of NetworkInfo using connectivity_plus package.
/// Handles platform-specific behavior, particularly for web platform.
class NetworkInfoImpl implements NetworkInfo {
  /// The connectivity instance for checking network status.
  final Connectivity connectivity;

  /// Creates a NetworkInfoImpl with the given connectivity instance.
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
