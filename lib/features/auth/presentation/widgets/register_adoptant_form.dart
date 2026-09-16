import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../../domain/auth_state.dart';
import 'terms_modal.dart';

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

class RegisterAdoptantForm extends ConsumerStatefulWidget {
  const RegisterAdoptantForm({super.key});

  @override
  ConsumerState<RegisterAdoptantForm> createState() =>
      _RegisterAdoptantFormState();
}

class _RegisterAdoptantFormState extends ConsumerState<RegisterAdoptantForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _acceptedTerms = false;
  File? _avatarFile;

  // Ciudad
  String? _selectedCity;
  List<String> _citySuggestions = [];

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_avatarFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una foto de perfil'),
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
        .signUpAdoptant(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          age: int.parse(_ageController.text.trim()),
          phone: _phoneController.text.trim(),
          city: _selectedCity!,
          avatarFile: _avatarFile!,
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
                  shape: BoxShape.circle,
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
              'Foto de perfil *',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 24),

          // Nombre
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre *',
              hintText: 'Tu nombre',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty)
                return 'El nombre es requerido';
              if (v.trim().length < 3) {
                return 'El nombre debe tener al menos 3 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Apellido
          TextFormField(
            controller: _lastNameController,
            decoration: const InputDecoration(
              labelText: 'Apellido *',
              hintText: 'Tu apellido',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'El apellido es requerido'
                : null,
          ),
          const SizedBox(height: 16),

          // Edad — solo números
          TextFormField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Edad *',
              hintText: 'Tu edad',
              prefixIcon: Icon(Icons.cake_outlined),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'La edad es requerida';
              final age = int.tryParse(v.trim());
              if (age == null || age < 18 || age > 100) {
                return 'Ingresa una edad válida (mayor de 18)';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Teléfono — solo números
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
          const SizedBox(height: 16),

          // Ciudad con autocomplete
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

          // Email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico *',
              hintText: 'your@email.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty)
                return 'El correo es requerido';
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
                : const Text('Crear cuenta'),
          ),
        ],
      ),
    );
  }
}
