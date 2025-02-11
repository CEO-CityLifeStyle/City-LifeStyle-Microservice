import 'package:connectivity_plus/connectivity_plus.dart';

Future<bool> isConnected() async {
  final connectivityResult = await Connectivity().checkConnectivity();
  return connectivityResult != ConnectivityResult.none;
}

Stream<bool> onConnectivityChanged() {
  return Connectivity().onConnectivityChanged.map(
    (ConnectivityResult result) => result != ConnectivityResult.none,
  );
}
