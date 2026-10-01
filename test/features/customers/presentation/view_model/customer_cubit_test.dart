import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_task/core/errors/failure.dart';
import 'package:job_task/features/customers/data/models/customer_model.dart';
import 'package:job_task/features/customers/data/repositories/customer_repository.dart';
import 'package:job_task/features/customers/presentation/view_model/customer_cubit.dart';
import 'package:job_task/features/customers/presentation/view_model/customer_state.dart';

class FakeCustomerRepoForCubit extends Fake implements CustomerRepository {
  Either<Failure, List<CustomerModel>>? resultToReturn;

  @override
  Future<Either<Failure, List<CustomerModel>>> getCustomers({
    String? searchQuery,
  }) async {
    return resultToReturn!;
  }
}

void main() {
  late FakeCustomerRepoForCubit fakeRepo;
  late CustomerCubit cubit;

  setUp(() {
    fakeRepo = FakeCustomerRepoForCubit();
    cubit = CustomerCubit(customerRepository: fakeRepo);
  });

  tearDown(() {
    cubit.close();
  });

  group('CustomerCubit', () {
    test('initial state is CustomerInitial', () {
      expect(cubit.state, isA<CustomerInitial>());
    });

    test('emits [CustomerLoading, CustomerSuccess] on successful load',
        () async {
      const customers = [CustomerModel(id: 1, name: 'Alice')];
      fakeRepo.resultToReturn = const Right(customers);

      expectLater(
        cubit.stream,
        emitsInOrder([
          isA<CustomerLoading>(),
          isA<CustomerSuccess>(),
        ]),
      );

      cubit.fetchCustomers();
    });

    test('emits [CustomerLoading, CustomerEmpty] when list is empty', () async {
      fakeRepo.resultToReturn = const Right([]);

      expectLater(
        cubit.stream,
        emitsInOrder([
          isA<CustomerLoading>(),
          isA<CustomerEmpty>(),
        ]),
      );

      cubit.fetchCustomers();
    });

    test('emits [CustomerLoading, CustomerFailure] on failure', () async {
      fakeRepo.resultToReturn =
          const Left(ServerFailure('Connection error'));

      expectLater(
        cubit.stream,
        emitsInOrder([
          isA<CustomerLoading>(),
          isA<CustomerFailure>(),
        ]),
      );

      cubit.fetchCustomers();
    });
  });
}
