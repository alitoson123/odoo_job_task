import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../auth/presentation/view_model/auth_cubit.dart';
import '../../data/models/customer_model.dart';
import '../view_model/customer_cubit.dart';
import '../view_model/customer_state.dart';
import '../widgets/customer_list_item.dart';
import '../widgets/customer_search_field.dart';
import '../widgets/customer_state_views.dart';
import '../widgets/sales_orders_action_button.dart';

/// Screen displaying searchable and refreshable list of Odoo customers.
class CustomerListView extends StatelessWidget {
  const CustomerListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CustomerCubit>()..fetchCustomers(),
      child: const _CustomerListScaffold(),
    );
  }
}

class _CustomerListScaffold extends StatelessWidget {
  const _CustomerListScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          const SalesOrdersActionButton(),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              context.read<AuthCubit>().logout();
              context.go(AppRouter.login);
            },
          ),
        ],
      ),
      body: BlocBuilder<CustomerCubit, CustomerState>(
        builder: (context, state) {
          final isOffline = (state is CustomerSuccess && state.isOffline) ||
              (state is CustomerEmpty && state.isOffline);

          return Column(
            children: [
              if (isOffline) const OfflineBanner(),
              CustomerSearchField(
                onChanged: (query) {
                  context.read<CustomerCubit>().onSearchChanged(query);
                },
              ),
              Expanded(
                child: _buildBody(context, state),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, CustomerState state) {
    if (state is CustomerLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is CustomerEmpty) {
      return CustomerEmptyView(
        onRefresh: () => context.read<CustomerCubit>().refresh(),
      );
    }
    if (state is CustomerFailure) {
      return CustomerErrorView(
        message: state.message,
        onRetry: () => context.read<CustomerCubit>().refresh(),
      );
    }
    if (state is CustomerSuccess) {
      return _buildList(context, state.customers);
    }
    return const SizedBox.shrink();
  }

  Widget _buildList(BuildContext context, List<CustomerModel> customers) {
    return RefreshIndicator(
      onRefresh: () => context.read<CustomerCubit>().refresh(),
      child: ListView.builder(
        itemCount: customers.length,
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemBuilder: (context, index) {
          final customer = customers[index];
          return CustomerListItem(
            customer: customer,
            onTap: () async {
              await context.push(
                AppRouter.customerDetails,
                extra: customer,
              );
              if (context.mounted) {
                context.read<CustomerCubit>().refresh();
              }
            },
          );
        },
      ),
    );
  }
}
