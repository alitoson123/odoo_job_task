import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_task/core/errors/failure.dart';
import 'package:job_task/features/auth/data/repositories/auth_repository.dart';
import 'package:job_task/features/auth/presentation/view_model/auth_cubit.dart';
import 'package:job_task/features/customers/presentation/widgets/sales_orders_action_button.dart';
import 'package:job_task/features/orders/data/repositories/order_repository.dart';

class FakeOrderRepository extends Fake implements OrderRepository {
  Either<Failure, bool> checkResult = const Right(true);
  int? lastUserIdChecked;

  @override
  Future<Either<Failure, bool>> checkIsInternalUser(int userId) async {
    lastUserIdChecked = userId;
    return checkResult;
  }
}

class FakeAuthRepository extends Fake implements AuthRepository {
  int? savedUserId;

  @override
  Future<({String? apiKey, int? userId, String? username})>
  getSavedCredentials() async {
    if (savedUserId == null) {
      return (username: null, apiKey: null, userId: null);
    }
    return (username: 'Alice', apiKey: 'key_123', userId: savedUserId);
  }
}

void main() {
  late FakeOrderRepository fakeOrderRepo;
  late FakeAuthRepository fakeAuthRepo;
  late AuthCubit authCubit;

  setUp(() {
    fakeOrderRepo = FakeOrderRepository();
    fakeAuthRepo = FakeAuthRepository();
    authCubit = AuthCubit(authRepository: fakeAuthRepo);
  });

  tearDown(() {
    authCubit.close();
  });

  Widget createWidget() {
    return BlocProvider<AuthCubit>.value(
      value: authCubit,
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: [
              SalesOrdersActionButton(orderRepository: fakeOrderRepo),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('shows Sales Orders button when checkIsInternalUser returns true', (
    tester,
  ) async {
    fakeOrderRepo.checkResult = const Right(true);
    fakeAuthRepo.savedUserId = 42;
    await authCubit.checkAuth();

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    expect(find.byTooltip('Sales Orders'), findsOneWidget);
    expect(fakeOrderRepo.lastUserIdChecked, equals(42));
  });

  testWidgets('hides Sales Orders button when checkIsInternalUser returns false', (
    tester,
  ) async {
    fakeOrderRepo.checkResult = const Right(false);
    fakeAuthRepo.savedUserId = 42;
    await authCubit.checkAuth();

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    expect(find.byTooltip('Sales Orders'), findsNothing);
    expect(fakeOrderRepo.lastUserIdChecked, equals(42));
  });

  testWidgets('hides Sales Orders button when checkIsInternalUser fails with Left', (
    tester,
  ) async {
    fakeOrderRepo.checkResult = const Left(ServerFailure('Access Denied'));
    fakeAuthRepo.savedUserId = 42;
    await authCubit.checkAuth();

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    expect(find.byTooltip('Sales Orders'), findsNothing);
  });

  testWidgets('hides Sales Orders button when not authenticated', (
    tester,
  ) async {
    fakeAuthRepo.savedUserId = null;
    await authCubit.checkAuth();

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    expect(find.byTooltip('Sales Orders'), findsNothing);
    expect(fakeOrderRepo.lastUserIdChecked, isNull);
  });
}
