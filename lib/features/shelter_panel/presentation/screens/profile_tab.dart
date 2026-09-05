import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../controllers/shelter_controller.dart';

class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _scheduleController = TextEditingController();
  bool _isEditing = false;
  bool _controllersLoaded = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _scheduleController.dispose();
    super.dispose();
  }

  void _loadControllers(shelter) {
    if (_controllersLoaded) return;
    _nameController.text = shelter.name;
    _descriptionController.text = shelter.description ?? '';
    _addressController.text = shelter.address ?? '';
    _cityController.text = shelter.city ?? '';
    _phoneController.text = shelter.phone ?? '';
    _emailController.text = shelter.email?.isNotEmpty == true
        ? shelter.email!
        : (Supabase.instance.client.auth.currentUser?.email ?? '');
    _scheduleController.text = shelter.schedule ?? '';
    _controllersLoaded = true;
  }

  Future<void> _pickAndUpdatePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked == null) return;

    final success = await ref
        .read(shelterControllerProvider.notifier)
        .updateAvatar(File(picked.path));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Foto actualizada exitosamente'
                : 'Error al actualizar la foto',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  Future<void> _saveChanges() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre del refugio es requerido'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final success = await ref
        .read(shelterControllerProvider.notifier)
        .updateShelter({
          'name': name,
          'description': _descriptionController.text.trim(),
          'address': _addressController.text.trim(),
          'city': _cityController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'schedule': _scheduleController.text.trim(),
        });

    if (mounted) {
      if (success) {
        setState(() {
          _isEditing = false;
          _controllersLoaded = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Perfil actualizado exitosamente'
                : 'Error al actualizar el perfil',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      ref.invalidate(shelterControllerProvider);
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shelterState = ref.watch(shelterControllerProvider);
    final shelter = shelterState.shelter;

    if (shelterState.isLoading && shelter == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (shelter == null) {
      return const Center(child: Text('No se encontró el refugio'));
    }

    _loadControllers(shelter);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Foto del refugio
          Stack(
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: AppColors.divider,
                backgroundImage: shelter.avatarUrl != null
                    ? NetworkImage(shelter.avatarUrl!)
                    : null,
                child: shelter.avatarUrl == null
                    ? const Icon(
                        Icons.home,
                        size: 40,
                        color: AppColors.textHint,
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickAndUpdatePhoto,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            shelter.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),

          // Botón editar / guardar
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_isEditing)
                TextButton(
                  onPressed: () => setState(() {
                    _isEditing = false;
                    _controllersLoaded = false;
                  }),
                  child: const Text('Cancelar'),
                ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: shelterState.isLoading
                    ? null
                    : () {
                        if (_isEditing) {
                          _saveChanges();
                        } else {
                          setState(() => _isEditing = true);
                        }
                      },
                icon: Icon(
                  _isEditing ? Icons.save_outlined : Icons.edit_outlined,
                ),
                label: Text(_isEditing ? 'Guardar' : 'Editar'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Campos
          _InfoField(
            label: 'Nombre del refugio',
            controller: _nameController,
            enabled: _isEditing,
            icon: Icons.home_outlined,
          ),
          _InfoField(
            label: 'Descripción',
            controller: _descriptionController,
            enabled: _isEditing,
            icon: Icons.description_outlined,
            maxLines: 3,
          ),

          // Dirección con helper text
          _InfoFieldWithHelper(
            label: 'Dirección',
            controller: _addressController,
            enabled: _isEditing,
            icon: Icons.location_on_outlined,
            hintText: 'Ej: Carrera 56 134',
            helperText: _isEditing
                ? 'Formato: Calle/Carrera Número, Ej: Carrera 56 Oeste 134'
                : null,
          ),

          _InfoField(
            label: 'Ciudad',
            controller: _cityController,
            enabled: _isEditing,
            icon: Icons.location_city_outlined,
          ),
          _InfoField(
            label: 'Teléfono',
            controller: _phoneController,
            enabled: _isEditing,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          _InfoField(
            label: 'Correo',
            controller: _emailController,
            enabled: _isEditing,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          _InfoField(
            label: 'Horario',
            controller: _scheduleController,
            enabled: _isEditing,
            icon: Icons.schedule_outlined,
            hintText: 'Ej: Lun-Sáb 9 AM - 6 PM',
          ),
          const SizedBox(height: 32),

          // Cerrar sesión
          OutlinedButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout, color: AppColors.error),
            label: const Text('Cerrar sesión'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final IconData icon;
  final int maxLines;
  final TextInputType keyboardType;
  final String? hintText;

  const _InfoField({
    required this.label,
    required this.controller,
    required this.enabled,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: enabled ? Colors.white : AppColors.background,
        ),
      ),
    );
  }
}

class _InfoFieldWithHelper extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final IconData icon;
  final int maxLines;
  final TextInputType keyboardType;
  final String? hintText;
  final String? helperText;

  const _InfoFieldWithHelper({
    required this.label,
    required this.controller,
    required this.enabled,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.hintText,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          helperText: helperText,
          helperMaxLines: 2,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: enabled ? Colors.white : AppColors.background,
        ),
      ),
    );
  }
}
