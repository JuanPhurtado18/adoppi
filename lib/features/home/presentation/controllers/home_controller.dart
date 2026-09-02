import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/home_repository.dart';
import '../../domain/home_state.dart';

class HomeController extends StateNotifier<HomeState> {
  final HomeRepository _repository;

  HomeController(this._repository) : super(const HomeState()) {
    loadAll();
  }

  Future<void> loadAll() async {
    await Future.wait([loadPets(), loadShelters()]);
  }

  Future<void> loadPets() async {
    state = state.copyWith(isLoadingPets: true);
    try {
      final pets = await _repository.getPets(
        species: state.selectedSpecies,
        searchQuery: state.searchQuery,
      );
      state = state.copyWith(pets: pets, isLoadingPets: false);
    } catch (e) {
      state = state.copyWith(
        isLoadingPets: false,
        errorMessage: 'Error al cargar mascotas',
      );
    }
  }

  Future<void> loadShelters() async {
    state = state.copyWith(isLoadingShelters: true);
    try {
      final shelters = await _repository.getShelters();
      state = state.copyWith(shelters: shelters, isLoadingShelters: false);
    } catch (e) {
      state = state.copyWith(
        isLoadingShelters: false,
        errorMessage: 'Error al cargar refugios',
      );
    }
  }

  void filterBySpecies(String species) {
    state = state.copyWith(selectedSpecies: species);
    loadPets();
  }

  void search(String query) {
    state = state.copyWith(searchQuery: query);
    loadPets();
  }

  void clearSearch() {
    state = state.copyWith(searchQuery: '');
    loadPets();
  }
}

final homeControllerProvider = StateNotifierProvider<HomeController, HomeState>(
  (ref) {
    return HomeController(ref.watch(homeRepositoryProvider));
  },
);
