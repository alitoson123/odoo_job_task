import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../data/models/sale_order_model.dart';
import '../view_model/orders_cubit.dart';
import '../view_model/orders_state.dart';
import '../widgets/order_list_item.dart';
import '../widgets/order_state_views.dart';

/// Screen displaying the list of Odoo sales orders.
class OrdersView extends StatelessWidget {
  const OrdersView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OrdersCubit>()..fetchOrders(),
      child: const _OrdersScaffold(),
    );
  }
}

class _OrdersScaffold extends StatelessWidget {
  const _OrdersScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Orders'),
      ),
      body: BlocBuilder<OrdersCubit, OrdersState>(
        builder: (context, state) {
          final isOffline = (state is OrdersSuccess && state.isOffline) ||
              (state is OrdersEmpty && state.isOffline);

          return Column(
            children: [
              if (isOffline) const OfflineBanner(),
              Expanded(child: _buildBody(context, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, OrdersState state) {
    if (state is OrdersLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is OrdersEmpty) {
      return OrderEmptyView(
        onRefresh: () => context.read<OrdersCubit>().refresh(),
      );
    }
    if (state is OrdersFailure) {
      return OrderErrorView(
        message: state.message,
        onRetry: () => context.read<OrdersCubit>().refresh(),
      );
    }
    if (state is OrdersSuccess) {
      return _buildOrdersList(context, state.orders);
    }
    return const SizedBox.shrink();
  }

  Widget _buildOrdersList(
    BuildContext context,
    List<SaleOrderModel> orders,
  ) {
    return RefreshIndicator(
      onRefresh: () => context.read<OrdersCubit>().refresh(),
      child: ListView.builder(
        itemCount: orders.length,
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemBuilder: (context, index) {
          final order = orders[index];
          return OrderListItem(
            order: order,
            onTap: () async {
              await context.push(
                AppRouter.orderDetails,
                extra: order,
              );
              if (context.mounted) {
                context.read<OrdersCubit>().refresh();
              }
            },
          );
        },
      ),
    );
  }
}
