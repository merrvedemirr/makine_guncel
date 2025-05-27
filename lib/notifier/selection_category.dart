import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectionState {
  final String? device;
  final String? brand;
  final String? model;

  SelectionState({this.device, this.brand, this.model});

  SelectionState copyWith({String? device, String? brand, String? model}) {
    return SelectionState(
      device: device ?? this.device,
      brand: brand ?? this.brand,
      model: model ?? this.model,
    );
  }
}

class SelectionNotifier extends StateNotifier<SelectionState> {
  SelectionNotifier() : super(SelectionState());

  void selectDevice(String device) {
    state = state.copyWith(device: device, brand: null, model: null);
  }

  void selectBrand(String brand) {
    state = state.copyWith(brand: brand, model: null);
  }

  void selectModel(String model) {
    state = state.copyWith(model: model);
  }
}

final selectionProvider = StateNotifierProvider<SelectionNotifier, SelectionState>(
  (ref) => SelectionNotifier(),
);
