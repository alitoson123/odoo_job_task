import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/service_locator.dart';
import '../../../auth/presentation/view_model/auth_cubit.dart';
import '../../../auth/presentation/view_model/auth_state.dart';
import '../../../orders/data/repositories/order_repository.dart';

/// App bar action button that conditionally displays the Sales Orders navigation
/// entry point only if the authenticated user has internal user permissions.
class SalesOrdersActionButton extends StatefulWidget {
  final OrderRepository? orderRepository;

  const SalesOrdersActionButton({
    super.key,
    this.orderRepository,
  });

  @override
  State<SalesOrdersActionButton> createState() =>
      _SalesOrdersActionButtonState();
}

class _SalesOrdersActionButtonState extends State<SalesOrdersActionButton> {
  Future<bool>? _checkFuture;
  int? _lastCheckedUserId;

  void _ensureCheck(int userId) {
    if (_lastCheckedUserId != userId) {
      _lastCheckedUserId = userId;
      _checkFuture = _verifyInternalUser(userId);
    }
  }

  Future<bool> _verifyInternalUser(int userId) async {
    try {
      final repository = widget.orderRepository ?? sl<OrderRepository>();
      final result = await repository.checkIsInternalUser(userId);
      return result.fold((_) => false, (isInternal) => isInternal);
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is! AuthSuccess || state.user.id <= 0) {
          return const SizedBox.shrink();
        }

        _ensureCheck(state.user.id);

        return FutureBuilder<bool>(
          future: _checkFuture,
          builder: (context, snapshot) {
            if (snapshot.data == true) {
              return IconButton(
                icon: const Icon(Icons.receipt_long),
                tooltip: 'Sales Orders',
                onPressed: () => context.push(AppRouter.orders),
              );
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }
}
