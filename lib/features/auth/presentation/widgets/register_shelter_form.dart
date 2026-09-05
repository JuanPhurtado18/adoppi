import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../../domain/auth_state.dart';
import 'terms_modal.dart';

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
  final _scheduleController = TextEditingController();
  bool _obscurePassword = true;
  bool _acceptedTerms = false;
  File? _avatarFile;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _scheduleController.dispose();
    super.dispose();
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
          content: Text('Por favor selecciona una foto del refugio'),
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
          city: _cityController.text.trim(),
          phone: _phoneController.text.trim(),
          description: _descriptionController.text.trim(),
          schedule: _scheduleController.text.trim(),
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
        children: [
          // Selector de foto
          GestureDetector(
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
          const SizedBox(height: 8),
          const Text(
            'Foto del refugio *',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Nombre del refugio
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre del refugio *',
              hintText: 'Fundación Amigos Peludos',
              prefixIcon: Icon(Icons.home_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El nombre del refugio es requerido';
              }
              return null;
            },
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
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'La descripción es requerida';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Dirección
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Dirección *',
              hintText: 'Ej: Calle 5 40-45',
              helperText:
                  'Escribe la dirección completa: Calle/Carrera Número, Ej: Carrera 56 134',
              helperMaxLines: 2,
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'La dirección es requerida';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Ciudad
          TextFormField(
            controller: _cityController,
            decoration: const InputDecoration(
              labelText: 'Ciudad *',
              hintText: 'Cali',
              prefixIcon: Icon(Icons.location_city_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'La ciudad es requerida';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Teléfono
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Teléfono *',
              hintText: '3001234567',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El teléfono es requerido';
              }
              if (value.trim().length < 7) {
                return 'Ingresa un teléfono válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          const SizedBox(height: 16),
          TextFormField(
            controller: _scheduleController,
            decoration: const InputDecoration(
              labelText: 'Horario *',
              hintText: 'Ej: Lun-Sáb 9 AM - 6 PM',
              prefixIcon: Icon(Icons.schedule_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El horario es requerido';
              }
              return null;
            },
          ),

          // Email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico *',
              hintText: 'contacto@refugio.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El correo es requerido';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
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
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'La contraseña es requerida';
              }
              if (value.length < 6) {
                return 'La contraseña debe tener al menos 6 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Términos y condiciones
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Checkbox(
                value: _acceptedTerms,
                onChanged: (value) =>
                    setState(() => _acceptedTerms = value ?? false),
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

          // Botón registrarse
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
