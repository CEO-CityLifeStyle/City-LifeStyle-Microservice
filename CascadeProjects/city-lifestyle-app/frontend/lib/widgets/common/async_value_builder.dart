import 'package:flutter/material.dart';

enum AsyncStatus {
  initial,
  loading,
  success,
  error,
}

class AsyncValue<T> {
  final AsyncStatus status;
  final T? data;
  final String? error;

  const AsyncValue._({
    required this.status,
    this.data,
    this.error,
  });

  factory AsyncValue.initial() => const AsyncValue._(status: AsyncStatus.initial);
  
  factory AsyncValue.loading() => const AsyncValue._(status: AsyncStatus.loading);
  
  factory AsyncValue.success(T data) => AsyncValue._(
    status: AsyncStatus.success,
    data: data,
  );
  
  factory AsyncValue.error(String error) => AsyncValue._(
    status: AsyncStatus.error,
    error: error,
  );

  bool get isInitial => status == AsyncStatus.initial;
  bool get isLoading => status == AsyncStatus.loading;
  bool get isSuccess => status == AsyncStatus.success;
  bool get isError => status == AsyncStatus.error;

  R when<R>({
    required R Function() initial,
    required R Function() loading,
    required R Function(T data) success,
    required R Function(String error) error,
  }) {
    switch (status) {
      case AsyncStatus.initial:
        return initial();
      case AsyncStatus.loading:
        return loading();
      case AsyncStatus.success:
        return success(data as T);
      case AsyncStatus.error:
        return error(error);
    }
  }
}

class AsyncValueBuilder<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) onSuccess;
  final Widget Function()? onLoading;
  final Widget Function(String error)? onError;
  final Widget Function()? onInitial;

  const AsyncValueBuilder({
    Key? key,
    required this.value,
    required this.onSuccess,
    this.onLoading,
    this.onError,
    this.onInitial,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return value.when(
      initial: () => onInitial?.call() ?? const SizedBox.shrink(),
      loading: () => onLoading?.call() ?? const Center(
        child: CircularProgressIndicator(),
      ),
      success: onSuccess,
      error: (error) => onError?.call(error) ?? ErrorView(
        message: error,
      ),
    );
  }
}
