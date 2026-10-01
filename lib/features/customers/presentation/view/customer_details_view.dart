import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../data/models/customer_model.dart';
import '../view_model/customer_details_cubit.dart';
import '../view_model/customer_details_state.dart';
import '../widgets/customer_info_tile.dart';
import '../widgets/customer_phone_card.dart';

/// Screen displaying customer contact info and allowing phone updates.
class CustomerDetailsView extends StatelessWidget {
  final CustomerModel initialCustomer;

  const CustomerDetailsView({super.key, required this.initialCustomer});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CustomerDetailsCubit>()
        ..loadDetails(initialCustomer.id),
      child: _CustomerDetailsScaffold(fallbackCustomer: initialCustomer),
    );
  }
}

class _CustomerDetailsScaffold extends StatelessWidget {
  final CustomerModel fallbackCustomer;

  const _CustomerDetailsScaffold({required this.fallbackCustomer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Details'),
      ),
      body: BlocConsumer<CustomerDetailsCubit, CustomerDetailsState>(
        listener: (context, state) {
          if (state is CustomerPhoneUpdateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: state.customer.isPendingSync
                    ? Colors.orange.shade800
                    : Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is CustomerPhoneUpdateFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final customer = _resolveCustomer(state);
          final isUpdating = state is CustomerPhoneUpdating;
          final isOffline = state is CustomerDetailsSuccess && state.isOffline;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isOffline)
                  const OfflineBanner(
                    message: 'Offline mode — displaying cached details',
                  ),
                CustomerInfoTile(
                  icon: Icons.person_outline,
                  title: 'Full Name',
                  value: customer.name,
                ),
                CustomerPhoneCard(
                  initialPhone: customer.phone,
                  isUpdating: isUpdating,
                  isPendingSync: customer.isPendingSync,
                  onSave: (newPhone) {
                    context.read<CustomerDetailsCubit>().updatePhone(
                          customerId: customer.id,
                          newPhone: newPhone,
                          currentCustomer: customer,
                        );
                  },
                ),
                CustomerInfoTile(
                  icon: Icons.email_outlined,
                  title: 'Email Address',
                  value: customer.email?.isNotEmpty == true
                      ? customer.email!
                      : 'No email provided',
                ),
                CustomerInfoTile(
                  icon: Icons.location_on_outlined,
                  title: 'Address',
                  value: customer.displayAddress,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  CustomerModel _resolveCustomer(CustomerDetailsState state) {
    if (state is CustomerDetailsSuccess) return state.customer;
    if (state is CustomerPhoneUpdating) return state.customer;
    if (state is CustomerPhoneUpdateSuccess) return state.customer;
    if (state is CustomerPhoneUpdateFailure) return state.customer;
    return fallbackCustomer;
  }
}
