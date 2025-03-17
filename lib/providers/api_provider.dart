import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient();
  ref.onDispose(() {
    client.dispose();
  });
  return client;
});

// Auth state provider
final authStateProvider = StateProvider<bool>((ref) => false);

// User profile provider
final userProfileProvider = FutureProvider((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  try {
    return await apiClient.getUserProfile();
  } catch (e) {
    apiClient.handleError(e);
    return null;
  }
});

// Payment history provider
final paymentHistoryProvider = FutureProvider((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  try {
    return await apiClient.getPaymentHistory();
  } catch (e) {
    apiClient.handleError(e);
    return <Map<String, dynamic>>[];
  }
});
