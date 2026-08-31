import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/shelter_repository.dart';
import '../../domain/pet.dart';

class PetState {
  final List<Pet> pets;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  const PetState({
    this.pets = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  PetState copyWith({
    List<Pet>? pets,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
  }) {
    return PetState(
      pets: pets ?? this.pets,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
    );
  }
}

class PetController extends StateNotifier<PetState> {
  final ShelterRepository _repository;
  final String shelterId;

  PetController(this._repository, this.shelterId) : super(const PetState()) {
    loadPets();
  }

  Future<void> loadPets() async {
    state = state.copyWith(isLoading: true);
    try {
      final pets = await _repository.getShelterPets(shelterId);
      state = state.copyWith(pets: pets, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar las mascotas',
      );
    }
  }

  Future<bool> createPet({
    required Pet pet,
    required File photoFile,
  }) async {
    state = state.copyWith(isSaving: true);
    try {
      await _repository.createPet(
        pet: pet,
        shelterId: shelterId,
        photoFile: photoFile,
      );
      await loadPets();
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Error al publicar la mascota',
      );
      return false;
    }
  }

  Future<bool> updatePet({
    required String petId,
    required Map<String, dynamic> data,
    File? newPhotoFile,
  }) async {
    state = state.copyWith(isSaving: true);
    try {
      await _repository.updatePet(
        petId: petId,
        data: data,
        newPhotoFile: newPhotoFile,
      );
      await loadPets();
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Error al actualizar la mascota',
      );
      return false;
    }
  }

  Future<bool> deletePet(String petId) async {
    try {
      await _repository.deletePet(petId);
      await loadPets();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error al eliminar la mascota');
      return false;
    }
  }
}

final petControllerProvider = StateNotifierProvider.family<PetController,
    PetState, String>((ref, shelterId) {
  return PetController(ref.watch(shelterRepositoryProvider), shelterId);
});