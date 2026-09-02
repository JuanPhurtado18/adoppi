import '../../shelter_panel/domain/pet.dart';
import '../../shelter_panel/domain/shelter.dart';

class HomeState {
  final List<Pet> pets;
  final List<Shelter> shelters;
  final bool isLoadingPets;
  final bool isLoadingShelters;
  final String selectedSpecies;
  final String searchQuery;
  final String? errorMessage;

  const HomeState({
    this.pets = const [],
    this.shelters = const [],
    this.isLoadingPets = false,
    this.isLoadingShelters = false,
    this.selectedSpecies = 'todos',
    this.searchQuery = '',
    this.errorMessage,
  });

  HomeState copyWith({
    List<Pet>? pets,
    List<Shelter>? shelters,
    bool? isLoadingPets,
    bool? isLoadingShelters,
    String? selectedSpecies,
    String? searchQuery,
    String? errorMessage,
  }) {
    return HomeState(
      pets: pets ?? this.pets,
      shelters: shelters ?? this.shelters,
      isLoadingPets: isLoadingPets ?? this.isLoadingPets,
      isLoadingShelters: isLoadingShelters ?? this.isLoadingShelters,
      selectedSpecies: selectedSpecies ?? this.selectedSpecies,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
    );
  }
}
