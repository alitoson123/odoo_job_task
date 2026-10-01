import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_task/core/errors/failure.dart';
import 'package:job_task/features/orders/data/models/sale_order_details_model.dart';
import 'package:job_task/features/orders/data/models/sale_order_model.dart';
import 'package:job_task/features/orders/data/repositories/order_repository.dart';
import 'package:job_task/features/orders/presentation/view_model/order_details_cubit.dart';
import 'package:job_task/features/orders/presentation/view_model/order_details_state.dart';

class FakeOrderRepoForDetails extends Fake implements OrderRepository {
  Either<Failure, ({SaleOrderModel order, List<SaleOrderDetailsModel> lines})>?
  detailsResult;
  Either<Failure, bool>? confirmResult;

  @override
  Future<
    Either<Failure, ({SaleOrderModel order, List<SaleOrderDetailsModel> lines})>
  >
  getOrderDetails(int orderId) async {
    return detailsResult!;
  }

  @override
  Future<Either<Failure, bool>> confirmOrder(int orderId) async {
    return confirmResult!;
  }
}

void main() {
  late FakeOrderRepoForDetails fakeRepo;
  late OrderDetailsCubit cubit;

  const sampleOrder = SaleOrderModel(
    id: 1,
    name: 'S00001',
    partnerId: 10,
    partnerName: 'Deco',
    state: 'draft',
  );

  const sampleLine = SaleOrderDetailsModel(
    id: 101,
    productId: 55,
    productName: 'Desk',
    name: 'Desk Pad',
    productUomQty: 2,
    priceUnit: 100,
    priceSubtotal: 200,
  );

  setUp(() {
    fakeRepo = FakeOrderRepoForDetails();
    cubit = OrderDetailsCubit(orderRepository: fakeRepo);
  });

  tearDown(() {
    cubit.close();
  });

  group('OrderDetailsCubit', () {
    test('initial state is OrderDetailsInitial', () {
      expect(cubit.state, isA<OrderDetailsInitial>());
    });

    test(
      'loadDetails emits [OrderDetailsLoading, OrderDetailsSuccess]',
      () async {
        fakeRepo.detailsResult = const Right((
          order: sampleOrder,
          lines: [sampleLine],
        ));

        expectLater(
          cubit.stream,
          emitsInOrder([
            isA<OrderDetailsLoading>(),
            isA<OrderDetailsSuccess>(),
          ]),
        );

        cubit.loadDetails(1);
      },
    );

    test(
      'loadDetails emits [OrderDetailsLoading, OrderDetailsFailure] on error',
      () async {
        fakeRepo.detailsResult = const Left(ServerFailure('Not found'));

        expectLater(
          cubit.stream,
          emitsInOrder([
            isA<OrderDetailsLoading>(),
            isA<OrderDetailsFailure>(),
          ]),
        );

        cubit.loadDetails(1);
      },
    );

    test(
      'confirmOrder emits [OrderConfirming, OrderConfirmSuccess] on success',
      () async {
        fakeRepo.confirmResult = const Right(true);

        expectLater(
          cubit.stream,
          emitsInOrder([isA<OrderConfirming>(), isA<OrderConfirmSuccess>()]),
        );

        cubit.confirmOrder(
          orderId: 1,
          currentOrder: sampleOrder,
          currentLines: [sampleLine],
        );
      },
    );

    test(
      'confirmOrder emits [OrderConfirming, OrderConfirmFailure] on error',
      () async {
        fakeRepo.confirmResult = const Left(ServerFailure('Confirm failed'));

        expectLater(
          cubit.stream,
          emitsInOrder([isA<OrderConfirming>(), isA<OrderConfirmFailure>()]),
        );

        cubit.confirmOrder(
          orderId: 1,
          currentOrder: sampleOrder,
          currentLines: [sampleLine],
        );
      },
    );
  });
}
