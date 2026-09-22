import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../../domain/auth_state.dart';
import 'terms_modal.dart';
import '../../../shelter_panel/presentation/screens/location_picker_screen.dart';

// ── Ciudades de Colombia ───────────────────────────────────────────────────
const _colombianCities = [
  'Bogotá',
  'Medellín',
  'Cali',
  'Barranquilla',
  'Cartagena',
  'Cúcuta',
  'Bucaramanga',
  'Pereira',
  'Santa Marta',
  'Ibagué',
  'Pasto',
  'Manizales',
  'Neiva',
  'Villavicencio',
  'Armenia',
  'Valledupar',
  'Montería',
  'Sincelejo',
  'Popayán',
  'Tunja',
  'Florencia',
  'Quibdó',
  'Riohacha',
  'San Andrés',
  'Mocoa',
  'Mitú',
  'Puerto Carreño',
  'Inírida',
  'Yopal',
  'Arauca',
  'Leticia',
  'Puerto Nariño',
  'Bello',
  'Itagüí',
  'Envigado',
  'Soledad',
  'Palmira',
  'Buenaventura',
  'Barrancabermeja',
  'Floridablanca',
  'Girón',
  'Piedecuesta',
  'Dosquebradas',
  'Tuluá',
  'Buga',
  'Cartago',
  'Sogamoso',
  'Duitama',
  'Zipaquirá',
  'Facatativá',
  'Chía',
  'Soacha',
  'Fusagasugá',
];

// ── Formateador de dirección ───────────────────────────────────────────────
class _AddressInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final filtered = newValue.text.replaceAll(
      RegExp(r'[^a-zA-ZáéíóúÁÉÍÓÚñÑ0-9\s#\-]'),
      '',
    );
    return newValue.copyWith(
      text: filtered,
      selection: TextSelection.collapsed(offset: filtered.length),
    );
  }
}

class RegisterShelterForm extends ConsumerStatefulWidget {
  const RegisterShelterForm({super.key});

  @override
  ConsumerState<RegisterShelterForm> createState() =>
      _RegisterShelterFormState();
}

class _RegisterShelterFormState extends ConsumerState<RegisterShelterForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _obscurePassword = true;
  bool _acceptedTerms = false;
  File? _avatarFile;

  // Ciudad
  String? _selectedCity;
  List<String> _citySuggestions = [];

  // Horario
  final List<String> _allDays = [
    'Lun',
    'Mar',
    'Mié',
    'Jue',
    'Vie',
    'Sáb',
    'Dom',
  ];
  final Set<String> _selectedDays = {};
  TimeOfDay _openTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _closeTime = const TimeOfDay(hour: 18, minute: 0);

  // Ubicación en mapa
  double? _pickedLat;
  double? _pickedLon;

  String get _scheduleText {
    if (_selectedDays.isEmpty) return '';
    final days = _allDays.where((d) => _selectedDays.contains(d)).toList();
    String dayRange;
    if (days.length == 1) {
      dayRange = days.first;
    } else {
      final firstIndex = _allDays.indexOf(days.first);
      final lastIndex = _allDays.indexOf(days.last);
      final continuous = days.length == lastIndex - firstIndex + 1;
      dayRange = continuous ? '${days.first}-${days.last}' : days.join(', ');
    }
    return '$dayRange ${_formatTime(_openTime)} - ${_formatTime(_closeTime)}';
  }

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onCityChanged(String value) {
    setState(() {
      _selectedCity = null;
      _citySuggestions = value.isEmpty
          ? []
          : _colombianCities
                .where((c) => c.toLowerCase().contains(value.toLowerCase()))
                .toList();
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _avatarFile = File(picked.path));
    }
  }

  Future<void> _pickTime(bool isOpen) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isOpen ? _openTime : _closeTime,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isOpen) {
          _openTime = picked;
        } else {
          _closeTime = picked;
        }
      });
    }
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLat: _pickedLat,
          initialLon: _pickedLon,
          cityName: _selectedCity,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _pickedLat = result.latitude;
        _pickedLon = result.longitude;
      });
    }
  }

  bool _isValidAddress(String value) {
    final regex = RegExp(
      r'^(Calle|Carrera|Avenida|Diagonal|Transversal|Cra|Cl|Av|Kr)\s+\d+[\w\s#\-]*$',
      caseSensitive: false,
    );
    return regex.hasMatch(value.trim());
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_avatarFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una foto del refugio'),
        ),
      );
      return;
    }
    if (_selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una ciudad de la lista'),
        ),
      );
      return;
    }
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona los días de atención'),
        ),
      );
      return;
    }
    if (_pickedLat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor selecciona la ubicación de tu refugio en el mapa',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes aceptar los términos y condiciones'),
        ),
      );
      return;
    }

    await ref
        .read(authControllerProvider.notifier)
        .signUpShelter(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          shelterName: _nameController.text.trim(),
          address: _addressController.text.trim(),
          city: _selectedCity!,
          phone: _phoneController.text.trim(),
          description: _descriptionController.text.trim(),
          schedule: _scheduleText,
          avatarFile: _avatarFile!,
          latitude: _pickedLat,
          longitude: _pickedLon,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage ?? 'Error desconocido'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foto
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary, width: 2),
                  image: _avatarFile != null
                      ? DecorationImage(
                          image: FileImage(_avatarFile!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _avatarFile == null
                    ? const Icon(
                        Icons.add_a_photo,
                        color: AppColors.primary,
                        size: 32,
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Foto del refugio *',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 24),

          // Nombre
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre del refugio *',
              hintText: 'Fundación Amigos Peludos',
              prefixIcon: Icon(Icons.home_outlined),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'El nombre del refugio es requerido'
                : null,
          ),
          const SizedBox(height: 16),

          // Descripción
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Descripción *',
              hintText: 'Cuéntanos sobre tu refugio o fundación',
              prefixIcon: Icon(Icons.description_outlined),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'La descripción es requerida'
                : null,
          ),
          const SizedBox(height: 16),

          // Dirección
          TextFormField(
            controller: _addressController,
            inputFormatters: [_AddressInputFormatter()],
            decoration: const InputDecoration(
              labelText: 'Dirección *',
              hintText: 'Ej: Calle 11 #46-45',
              helperText:
                  'Formato: Calle/Carrera/Avenida + Número. Ej: Calle 11 #46-45',
              helperMaxLines: 2,
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'La dirección es requerida';
              }
              if (!_isValidAddress(v)) {
                return 'Formato inválido. Ej: Calle 11 #46-45';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),

          // Ciudad
          TextFormField(
            controller: _cityController,
            onChanged: _onCityChanged,
            decoration: InputDecoration(
              labelText: 'Ciudad *',
              hintText: 'Escribe para buscar...',
              prefixIcon: const Icon(Icons.location_city_outlined),
              suffixIcon: _selectedCity != null
                  ? const Icon(Icons.check_circle, color: AppColors.success)
                  : null,
            ),
            validator: (_) => _selectedCity == null
                ? 'Selecciona una ciudad de la lista'
                : null,
          ),
          if (_citySuggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: _citySuggestions.length > 5
                    ? 5
                    : _citySuggestions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final city = _citySuggestions[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.location_city_outlined,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    title: Text(city, style: const TextStyle(fontSize: 14)),
                    onTap: () {
                      setState(() {
                        _selectedCity = city;
                        _cityController.text = city;
                        _citySuggestions = [];
                      });
                    },
                  );
                },
              ),
            ),
          const SizedBox(height: 16),

          // Selector de ubicación en mapa
          GestureDetector(
            onTap: _openLocationPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _pickedLat != null
                    ? AppColors.primary.withOpacity(0.06)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _pickedLat != null
                      ? AppColors.primary.withOpacity(0.4)
                      : AppColors.divider,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.map_outlined,
                    color: _pickedLat != null
                        ? AppColors.primary
                        : AppColors.textHint,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _pickedLat != null
                          ? 'Ubicación seleccionada ✓\nLat: ${_pickedLat!.toStringAsFixed(5)}, Lon: ${_pickedLon!.toStringAsFixed(5)}'
                          : 'Seleccionar ubicación exacta en el mapa *',
                      style: TextStyle(
                        fontSize: 13,
                        color: _pickedLat != null
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textHint,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 4, top: 4, bottom: 8),
            child: Text(
              'Mueve el pin al lugar exacto de tu refugio para que los adoptantes puedan encontrarte',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ),

          // Teléfono
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Teléfono *',
              hintText: '3001234567',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'El teléfono es requerido';
              }
              if (v.trim().length < 7) return 'Ingresa un teléfono válido';
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Horario
          const Text(
            'Horario de atención *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Días',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allDays.map((day) {
              final selected = _selectedDays.contains(day);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selectedDays.remove(day);
                    } else {
                      _selectedDays.add(day);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.divider,
                    ),
                  ),
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            'Horario',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickTime(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Apertura',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              _formatTime(_openTime),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('—', style: TextStyle(color: AppColors.textHint)),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickTime(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cierre',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              _formatTime(_closeTime),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_selectedDays.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.schedule_outlined,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _scheduleText,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico *',
              hintText: 'contacto@refugio.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'El correo es requerido';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                return 'Ingresa un correo válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Contraseña
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Contraseña *',
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'La contraseña es requerida';
              if (v.length < 6) {
                return 'La contraseña debe tener al menos 6 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Términos
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Checkbox(
                value: _acceptedTerms,
                onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                activeColor: AppColors.primary,
              ),
              Expanded(
                child: Wrap(
                  children: [
                    const Text(
                      'Acepto los ',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => TermsModal.show(context),
                      child: const Text(
                        'Términos y Condiciones',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Botón
          ElevatedButton(
            onPressed: authState.isLoading ? null : _submit,
            child: authState.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Crear refugio'),
          ),
        ],
      ),
    );
  }
}
