// lib/core/api/api_provider.dart
// Provides a singleton ApiClient and service instances for the app.

import 'api_client.dart';
import 'item_api.dart';
import 'po_api.dart';
import 'gr_api.dart';

class ApiProvider {
  static final ApiProvider _instance = ApiProvider._internal();
  factory ApiProvider() => _instance;
  ApiProvider._internal();

  final ApiClient client = ApiClient(baseUrl: 'http://localhost:8080/api/v1');

  late final ItemApi itemApi = ItemApi(client);
  late final PurchaseOrderApi poApi = PurchaseOrderApi(client);
  late final GoodsReceiptApi grApi = GoodsReceiptApi(client);
}
