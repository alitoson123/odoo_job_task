import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../data/models/sale_order_details_model.dart';
import '../../data/models/sale_order_model.dart';
import '../view_model/order_details_cubit.dart';
import '../view_model/order_details_state.dart';
import '../widgets/confirm_order_dialog.dart';
import '../widgets/order_confirm_button.dart';
import '../widgets/order_header_card.dart';
import '../widgets/order_lines_card.dart';
import '../widgets/order_totals_card.dart';

/// Screen displaying complete details of an Odoo sales order and products.
class OrderDetailsView extends StatelessWidget {
  final SaleOrderModel initialOrder;

  const OrderDetailsView({super.key, required this.initialOrder});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OrderDetailsCubit>()..loadDetails(initialOrder.id),
      child: _OrderDetailsScaffold(initialOrder: initialOrder),
    );
  }
}

class _OrderDetailsScaffold extends StatelessWidget {
  final SaleOrderModel initialOrder;

  const _OrderDetailsScaffold({required this.initialOrder});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrderDetailsCubit, OrderDetailsState>(
      listener: (context, state) {
        if (state is OrderConfirmSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green.shade700,
            ),
          );
        } else if (state is OrderConfirmFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      },
      builder: (context, state) {
        final order = _resolveOrder(state);
        final lines = _resolveLines(state);
        final isLoading = state is OrderDetailsLoading;
        final isConfirming = state is OrderConfirming;
        final isOffline = state is OrderDetailsSuccess && state.isOffline;

        return Scaffold(
          appBar: AppBar(title: Text(order.name)),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildContent(order, lines, isOffline),
          bottomNavigationBar: order.isConfirmable && !isOffline
              ? OrderConfirmButton(
                  isLoading: isConfirming,
                  onConfirm: () => _handleConfirm(context, order, lines),
                )
              : null,
        );
      },
    );
  }

  Widget _buildContent(
    SaleOrderModel order,
    List<SaleOrderDetailsModel> lines,
    bool isOffline,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (isOffline) ...[
          const OfflineBanner(message: 'Offline mode — displaying cached order details'),
          const SizedBox(height: 16),
        ],
        OrderHeaderCard(order: order),
        const SizedBox(height: 16),
        OrderLinesCard(lines: lines),
        const SizedBox(height: 16),
        OrderTotalsCard(order: order),
        const SizedBox(height: 24),
      ],
    );
  }

  SaleOrderModel _resolveOrder(OrderDetailsState state) {
    if (state is OrderDetailsSuccess) return state.order;
    if (state is OrderConfirming) return state.order;
    if (state is OrderConfirmSuccess) return state.order;
    if (state is OrderConfirmFailure) return state.order;
    return initialOrder;
  }

  List<SaleOrderDetailsModel> _resolveLines(OrderDetailsState state) {
    if (state is OrderDetailsSuccess) return state.lines;
    if (state is OrderConfirming) return state.lines;
    if (state is OrderConfirmSuccess) return state.lines;
    if (state is OrderConfirmFailure) return state.lines;
    return const [];
  }

  Future<void> _handleConfirm(
    BuildContext context,
    SaleOrderModel order,
    List<SaleOrderDetailsModel> lines,
  ) async {
    final confirmed = await ConfirmOrderDialog.show(context, order.name);
    if (confirmed == true && context.mounted) {
      context.read<OrderDetailsCubit>().confirmOrder(
            orderId: order.id,
            currentOrder: order,
            currentLines: lines,
          );
    }
  }
}
