import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_task/core/errors/failure.dart';
import 'package:job_task/features/customers/data/models/customer_model.dart';
import 'package:job_task/features/customers/data/repositories/customer_repository.dart';
import 'package:job_task/features/customers/presentation/view_model/customer_details_cubit.dart';
import 'package:job_task/features/customers/presentation/view_model/customer_details_state.dart';

class FakeCustomerRepoForDetails extends Fake implements CustomerRepository {
  Either<Failure, CustomerModel>? detailsResult;
  Either<Failure, bool>? updateResult;

  @override
  Future<Either<Failure, CustomerModel>> getCustomerDetails(
    int customerId,
  ) async {
    return detailsResult!;
  }

  @override
  Future<Either<Failure, bool>> updateCustomerPhone({
    required int customerId,
    required String newPhone,
  }) async {
    return updateResult!;
  }
}

void main() {
  late FakeCustomerRepoForDetails fakeRepo;
  late CustomerDetailsCubit cubit;

  setUp(() {
    fakeRepo = FakeCustomerRepoForDetails();
    cubit = CustomerDetailsCubit(customerRepository: fakeRepo);
  });

  tearDown(() {
    cubit.close();
  });

  group('CustomerDetailsCubit', () {
    test('initial state is CustomerDetailsInitial', () {
      expect(cubit.state, isA<CustomerDetailsInitial>());
    });

    test('loadDetails emits [Loading, Success]', () async {
      const customer = CustomerModel(id: 1, name: 'Bob');
      fakeRepo.detailsResult = const Right(customer);

      expectLater(
        cubit.stream,
        emitsInOrder([
          isA<CustomerDetailsLoading>(),
          isA<CustomerDetailsSuccess>(),
        ]),
      );

      cubit.loadDetails(1);
    });

    test('updatePhone emits [PhoneUpdating, PhoneUpdateSuccess]', () async {
      const current = CustomerModel(id: 1, name: 'Bob', phone: '111');
      fakeRepo.updateResult = const Right(true);

      expectLater(
        cubit.stream,
        emitsInOrder([
          isA<CustomerPhoneUpdating>(),
          isA<CustomerPhoneUpdateSuccess>(),
        ]),
      );

      cubit.updatePhone(
        customerId: 1,
        newPhone: '999',
        currentCustomer: current,
      );
    });
  });
}
