// lib/app.dart
// App root — configures GoRouter with the AppShell and three feature routes.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'widgets/app_shell.dart';
import 'features/items/items_page.dart';
import 'features/purchase_orders/po_page.dart';
import 'features/goods_receipts/gr_page.dart';

final _router = GoRouter(
  initialLocation: '/items',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/items',
          builder: (context, state) => const ItemsPage(),
        ),
        GoRoute(
          path: '/purchase-orders',
          builder: (context, state) => const PoPage(),
        ),
        GoRoute(
          path: '/goods-receipts',
          builder: (context, state) => const GrPage(),
        ),
      ],
    ),
  ],
);

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SC3 Pembelian & Penerimaan Barang',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
