import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/shelter_repository.dart';
import '../../domain/shelter.dart';

class ShelterState {
  final Shelter? shelter;
  final bool isLoading;
  final String? errorMessage;

  const ShelterState({this.shelter, this.isLoading = false, this.errorMessage});

  ShelterState copyWith({
    Shelter? shelter,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ShelterState(
      shelter: shelter ?? this.shelter,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class ShelterController extends StateNotifier<ShelterState> {
  final ShelterRepository _repository;

  ShelterController(this._repository) : super(const ShelterState()) {
    loadShelter();
  }

  Future<void> loadShelter() async {
    state = state.copyWith(isLoading: true);
    try {
      final shelter = await _repository.getCurrentShelter();
      state = state.copyWith(shelter: shelter, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar el refugio',
      );
    }
  }

  Future<bool> updateShelter(Map<String, dynamic> data) async {
    if (state.shelter == null) return false;
    state = state.copyWith(isLoading: true);
    try {
      await _repository.updateShelter(shelterId: state.shelter!.id, data: data);

      // Geolocalizar si hay dirección
      final address = data['address'] as String?;
      final city = data['city'] as String?;
      if (address != null &&
          address.isNotEmpty &&
          city != null &&
          city.isNotEmpty) {
        await _repository.geocodeAndUpdateShelter(
          shelterId: state.shelter!.id,
          address: address,
          city: city,
        );
      }

      await loadShelter();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al actualizar el refugio',
      );
      return false;
    }
  }

  Future<bool> updateAvatar(File file) async {
    if (state.shelter == null) return false;
    state = state.copyWith(isLoading: true);
    try {
      final userId = state.shelter!.userId;
      await _repository.updateShelterAvatar(
        userId: userId,
        shelterId: state.shelter!.id,
        file: file,
      );
      await loadShelter();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al actualizar la foto',
      );
      return false;
    }
  }
}

final shelterControllerProvider =
    StateNotifierProvider<ShelterController, ShelterState>((ref) {
      return ShelterController(ref.watch(shelterRepositoryProvider));
    });
