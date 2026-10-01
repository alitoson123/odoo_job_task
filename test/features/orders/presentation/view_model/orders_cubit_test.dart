import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_task/core/errors/failure.dart';
import 'package:job_task/features/orders/data/models/sale_order_model.dart';
import 'package:job_task/features/orders/data/repositories/order_repository.dart';
import 'package:job_task/features/orders/presentation/view_model/orders_cubit.dart';
import 'package:job_task/features/orders/presentation/view_model/orders_state.dart';

class FakeOrderRepositoryForCubit extends Fake implements OrderRepository {
  Either<Failure, List<SaleOrderModel>>? ordersResult;

  @override
  Future<Either<Failure, List<SaleOrderModel>>> getOrders() async {
    return ordersResult!;
  }
}

void main() {
  late FakeOrderRepositoryForCubit fakeRepo;
  late OrdersCubit cubit;

  setUp(() {
    fakeRepo = FakeOrderRepositoryForCubit();
    cubit = OrdersCubit(orderRepository: fakeRepo);
  });

  tearDown(() {
    cubit.close();
  });

  group('OrdersCubit', () {
    test('initial state is OrdersInitial', () {
      expect(cubit.state, isA<OrdersInitial>());
    });

    test('emits [OrdersLoading, OrdersSuccess] when orders are found', () async {
      const orders = [
        SaleOrderModel(
          id: 1,
          name: 'S00001',
          partnerId: 10,
          partnerName: 'Deco',
          state: 'draft',
        ),
      ];
      fakeRepo.ordersResult = const Right(orders);

      expectLater(
        cubit.stream,
        emitsInOrder([
          isA<OrdersLoading>(),
          isA<OrdersSuccess>(),
        ]),
      );

      cubit.fetchOrders();
    });

    test('emits [OrdersLoading, OrdersEmpty] when list is empty', () async {
      fakeRepo.ordersResult = const Right([]);

      expectLater(
        cubit.stream,
        emitsInOrder([
          isA<OrdersLoading>(),
          isA<OrdersEmpty>(),
        ]),
      );

      cubit.fetchOrders();
    });

    test('emits [OrdersLoading, OrdersFailure] on failure', () async {
      fakeRepo.ordersResult = const Left(ServerFailure('Network error'));

      expectLater(
        cubit.stream,
        emitsInOrder([
          isA<OrdersLoading>(),
          isA<OrdersFailure>(),
        ]),
      );

      cubit.fetchOrders();
    });
  });
}
