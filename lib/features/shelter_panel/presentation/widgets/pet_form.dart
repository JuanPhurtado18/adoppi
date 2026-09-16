import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../domain/pet.dart';

const Map<String, List<String>> _breedsBySpecies = {
  'Perro': [
    'Mestizo',
    'Labrador Retriever',
    'Golden Retriever',
    'Pastor Alemán',
    'Bulldog Francés',
    'Bulldog Inglés',
    'Beagle',
    'Poodle',
    'Rottweiler',
    'Yorkshire Terrier',
    'Boxer',
    'Dachshund',
    'Siberian Husky',
    'Doberman',
    'Gran Danés',
    'Shih Tzu',
    'Chihuahua',
    'Pomerania',
    'Schnauzer',
    'Border Collie',
    'Australian Shepherd',
    'Cocker Spaniel',
    'Maltés',
    'Bichón Frisé',
    'Pug',
    'Akita',
    'Shar Pei',
    'Weimaraner',
    'Bernese Mountain Dog',
    'Samoyedo',
    'Chow Chow',
    'Dalmatian',
    'Basset Hound',
    'Bullmastiff',
    'Cane Corso',
    'Pitbull',
    'American Bully',
    'Jack Russell Terrier',
    'West Highland Terrier',
    'Boston Terrier',
    'Lhasa Apso',
    'Pekinés',
    'Spitz Alemán',
    'Setter Irlandés',
    'Pointer',
    'Vizsla',
    'Greyhound',
    'Whippet',
    'Borzoi',
    'Afghan Hound',
    'Saluki',
    'Malinois',
    'Bouvier des Flandres',
  ],
  'Gato': [
    'Mestizo',
    'Persa',
    'Siamés',
    'Maine Coon',
    'Ragdoll',
    'Bengalí',
    'Abisinio',
    'Sphynx',
    'Scottish Fold',
    'British Shorthair',
    'American Shorthair',
    'Russian Blue',
    'Birmano',
    'Noruego del Bosque',
    'Angora Turco',
    'Van Turco',
    'Himalayo',
    'Devon Rex',
    'Cornish Rex',
    'Manx',
    'Burmés',
    'Tonkinés',
    'Somali',
    'Ocicato',
    'Savannah',
    'Chartreux',
    'Egyptian Mau',
    'Selkirk Rex',
    'Exotic Shorthair',
  ],
  'Otro': ['No aplica'],
};

class PetForm extends StatefulWidget {
  final Pet? pet;
  final bool isSaving;
  final void Function(Pet pet, File? photoFile) onSubmit;

  const PetForm({
    super.key,
    this.pet,
    required this.isSaving,
    required this.onSubmit,
  });

  @override
  State<PetForm> createState() => _PetFormState();
}

class _PetFormState extends State<PetForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _storyController = TextEditingController();
  final _healthController = TextEditingController();

  String _species = 'perro';
  String? _size;
  String? _gender;
  String _adoptionStatus = 'disponible';
  int? _ageMonths;
  bool _vaccinated = false;
  bool _sterilized = false;
  bool _dewormed = false;
  bool _childFriendly = false;
  File? _photoFile;

  bool get _isEditing => widget.pet != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final p = widget.pet!;
      _nameController.text = p.name;
      _breedController.text = p.breed ?? '';
      _descriptionController.text = p.description ?? '';
      _storyController.text = p.story ?? '';
      _healthController.text = p.healthStatus ?? '';
      _species = p.species;
      _size = p.size;
      _gender = p.gender;
      _adoptionStatus = p.adoptionStatus;
      _ageMonths = p.ageMonths;
      if (p.ageMonths != null) {
        _ageController.text = p.ageMonths.toString();
      }
      _vaccinated = p.vaccinated;
      _sterilized = p.sterilized;
      _dewormed = p.dewormed;
      _childFriendly = p.childFriendly;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _descriptionController.dispose();
    _storyController.dispose();
    _healthController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _photoFile = File(picked.path));
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_isEditing && _photoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una foto de la mascota')),
      );
      return;
    }

    final pet = Pet(
      id: widget.pet?.id ?? '',
      shelterId: widget.pet?.shelterId ?? '',
      name: _nameController.text.trim(),
      species: _species,
      breed: _breedController.text.trim().isEmpty
          ? null
          : _breedController.text.trim(),
      ageMonths: _ageMonths,
      size: _size,
      gender: _gender,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      story: _storyController.text.trim().isEmpty
          ? null
          : _storyController.text.trim(),
      healthStatus: _healthController.text.trim().isEmpty
          ? null
          : _healthController.text.trim(),
      vaccinated: _vaccinated,
      sterilized: _sterilized,
      dewormed: _dewormed,
      childFriendly: _childFriendly,
      adoptionStatus: _adoptionStatus,
      createdAt: widget.pet?.createdAt ?? DateTime.now(),
    );

    widget.onSubmit(pet, _photoFile);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto
              Center(
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary, width: 2),
                      image: _photoFile != null
                          ? DecorationImage(
                              image: FileImage(_photoFile!),
                              fit: BoxFit.cover,
                            )
                          : (widget.pet?.mainPhotoUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(
                                      widget.pet!.mainPhotoUrl!,
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                : null),
                    ),
                    child:
                        (_photoFile == null && widget.pet?.mainPhotoUrl == null)
                        ? const Icon(
                            Icons.add_a_photo,
                            color: AppColors.primary,
                            size: 36,
                          )
                        : null,
                  ),
                ),
              ),
              if (!_isEditing)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Foto de la mascota *',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Nombre
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre *'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'El nombre es requerido'
                    : null,
              ),
              const SizedBox(height: 16),

              // Especie
              _SectionLabel(label: 'Especie *'),
              const SizedBox(height: 8),
              _ChipGroup(
                options: const ['Perro', 'Gato', 'Otro'],
                selected: _species,
                onSelected: (v) => setState(() {
                  _species = v;
                  _breedController.clear();
                }),
              ),
              const SizedBox(height: 16),

              // Género
              _SectionLabel(label: 'Género'),
              const SizedBox(height: 8),
              _ChipGroup(
                options: const ['Macho', 'Hembra'],
                selected: _gender,
                onSelected: (v) => setState(() => _gender = v),
                allowDeselect: true,
              ),
              const SizedBox(height: 16),

              // Tamaño
              _SectionLabel(label: 'Tamaño'),
              const SizedBox(height: 8),
              _ChipGroup(
                options: const ['Pequeño', 'Mediano', 'Grande'],
                selected: _size,
                onSelected: (v) => setState(() => _size = v),
                allowDeselect: true,
              ),
              const SizedBox(height: 16),

              // Edad
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Edad en meses',
                  hintText: 'Ej: 6 para 6 meses, 24 para 2 años',
                  helperText: 'Rango permitido: 1 mes a 144 meses (12 años)',
                  helperMaxLines: 2,
                ),
                onChanged: (v) => _ageMonths = int.tryParse(v),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  final age = int.tryParse(value.trim());
                  if (age == null) return 'Ingresa solo números';
                  if (age < 1) return 'La edad mínima es 1 mes';
                  if (age > 144) return 'La edad máxima es 144 meses (12 años)';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Raza con autocomplete
              Autocomplete<String>(
                key: ValueKey(_species),
                initialValue: TextEditingValue(text: _breedController.text),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  final breeds = _breedsBySpecies[_species] ?? [];
                  if (textEditingValue.text.isEmpty) {
                    return breeds;
                  }
                  return breeds.where(
                    (breed) => breed.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    ),
                  );
                },
                onSelected: (String selection) {
                  setState(() {
                    _breedController.text = selection;
                  });
                  FocusScope.of(context).unfocus();
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) {
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Raza',
                          hintText: 'Escribe para buscar una raza',
                          prefixIcon: Icon(Icons.search),
                          helperText: 'Selecciona una raza de la lista',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty)
                            return null;
                          final breeds = _breedsBySpecies[_species] ?? [];
                          if (!breeds.contains(value.trim())) {
                            return 'Selecciona una raza válida de la lista';
                          }
                          return null;
                        },
                      );
                    },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final option = options.elementAt(index);
                            return ListTile(
                              dense: true,
                              title: Text(
                                option,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              onTap: () => onSelected(option),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Descripción
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Cuéntanos sobre la personalidad de la mascota',
                ),
              ),
              const SizedBox(height: 16),

              // Historia
              TextFormField(
                controller: _storyController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Historia',
                  hintText: '¿Cómo llegó al refugio?',
                ),
              ),
              const SizedBox(height: 16),

              // Salud
              TextFormField(
                controller: _healthController,
                decoration: const InputDecoration(
                  labelText: 'Estado de salud',
                  hintText: 'Ej: Excelente, en tratamiento por...',
                ),
              ),
              const SizedBox(height: 20),

              // Checkboxes de salud
              _SectionLabel(label: 'Condiciones'),
              _CheckItem(
                label: 'Vacunado',
                value: _vaccinated,
                onChanged: (v) => setState(() => _vaccinated = v),
              ),
              _CheckItem(
                label: 'Esterilizado',
                value: _sterilized,
                onChanged: (v) => setState(() => _sterilized = v),
              ),
              _CheckItem(
                label: 'Desparasitado',
                value: _dewormed,
                onChanged: (v) => setState(() => _dewormed = v),
              ),
              _CheckItem(
                label: 'Compatible con niños',
                value: _childFriendly,
                onChanged: (v) => setState(() => _childFriendly = v),
              ),
              const SizedBox(height: 20),

              // Estado de adopción
              _SectionLabel(label: 'Estado de adopción'),
              const SizedBox(height: 8),
              _ChipGroup(
                options: const ['disponible', 'en_proceso', 'adoptado'],
                labels: const ['Disponible', 'En proceso', 'Adoptado'],
                selected: _adoptionStatus,
                onSelected: (v) => setState(() => _adoptionStatus = v),
              ),
              const SizedBox(height: 32),

              // Botón
              ElevatedButton(
                onPressed: widget.isSaving ? null : _submit,
                child: widget.isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isEditing ? 'Guardar cambios' : 'Publicar mascota'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _ChipGroup extends StatelessWidget {
  final List<String> options;
  final List<String>? labels;
  final String? selected;
  final void Function(String) onSelected;
  final bool allowDeselect;

  const _ChipGroup({
    required this.options,
    this.labels,
    required this.selected,
    required this.onSelected,
    this.allowDeselect = false,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: options.asMap().entries.map((entry) {
        final value = entry.value;
        final label = labels?[entry.key] ?? value;
        final isSelected = selected == value;
        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (v) {
            if (allowDeselect && isSelected) {
              onSelected('');
            } else {
              onSelected(value);
            }
          },
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 13,
          ),
          backgroundColor: AppColors.background,
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        );
      }).toList(),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final String label;
  final bool value;
  final void Function(bool) onChanged;

  const _CheckItem({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: Text(
        label,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      ),
      value: value,
      onChanged: (v) => onChanged(v ?? false),
      activeColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
    );
  }
}
