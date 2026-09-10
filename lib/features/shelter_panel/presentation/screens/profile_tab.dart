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
  final notificationsEnabledProvider = StateProvider<bool>((ref) => true);

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

  Future<void> _openEditProfile(shelter) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditShelterModal(shelter: shelter),
    );
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
    final user = Supabase.instance.client.auth.currentUser;
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);

    if (shelterState.isLoading && shelter == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (shelter == null) {
      return const Center(child: Text('No se encontró el refugio'));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header morado
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 32),
              color: AppColors.primary,
              child: Stack(
                children: [
                  // Botón editar esquina superior derecha
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _openEditProfile(shelter),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  // Contenido centrado
                  Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.3),
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: ClipOval(
                              child: shelter.avatarUrl != null
                                  ? Image.network(
                                      shelter.avatarUrl!,
                                      fit: BoxFit.cover,
                                      width: 96,
                                      height: 96,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.home,
                                        size: 48,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.home,
                                      size: 48,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickAndUpdatePhoto,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: AppColors.primary,
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        shelter.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.email_outlined,
                            color: Colors.white.withOpacity(0.8),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user?.email ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                      if (shelter.city != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              color: Colors.white.withOpacity(0.8),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              shelter.city!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Settings
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Settings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: _SettingsTile(
                      icon: Icons.notifications_outlined,
                      label: 'Notificaciones',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            notificationsEnabled ? 'Activadas' : 'Desactivadas',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.textHint,
                            size: 20,
                          ),
                        ],
                      ),
                      onTap: () {
                        ref.read(notificationsEnabledProvider.notifier).state =
                            !notificationsEnabled;
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  Material(
                    color: Colors.transparent,
                    child: _SettingsTile(
                      icon: Icons.location_on_outlined,
                      label: 'Ubicación',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            shelter.city ?? 'No definida',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.textHint,
                            size: 20,
                          ),
                        ],
                      ),
                      onTap: () {},
                    ),
                  ),
                  const Divider(height: 1),
                  Material(
                    color: Colors.transparent,
                    child: _SettingsTile(
                      icon: Icons.shield_outlined,
                      label: 'Privacy & Safety',
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.textHint,
                        size: 20,
                      ),
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const _PrivacySafetyModal(),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Material(
                    color: Colors.transparent,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                    child: _SettingsTile(
                      icon: Icons.help_outline,
                      label: 'Help & Support',
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.textHint,
                        size: 20,
                      ),
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const _HelpSupportModal(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Cerrar sesión
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout, color: AppColors.error),
                label: const Text('Cerrar sesión'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Center(
              child: Column(
                children: [
                  const Text(
                    'Version 1.0.0',
                    style: TextStyle(fontSize: 12, color: AppColors.textHint),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Made with ',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                      Icon(Icons.favorite, color: AppColors.error, size: 12),
                      Text(
                        ' for pets',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Modal edición del refugio ──────────────────────────────────────────────

class _EditShelterModal extends ConsumerStatefulWidget {
  final dynamic shelter;

  const _EditShelterModal({required this.shelter});

  @override
  ConsumerState<_EditShelterModal> createState() => _EditShelterModalState();
}

class _EditShelterModalState extends ConsumerState<_EditShelterModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _phoneController;
  late final TextEditingController _scheduleController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.shelter.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.shelter.description ?? '',
    );
    _addressController = TextEditingController(
      text: widget.shelter.address ?? '',
    );
    _cityController = TextEditingController(text: widget.shelter.city ?? '');
    _phoneController = TextEditingController(text: widget.shelter.phone ?? '');
    _scheduleController = TextEditingController(
      text: widget.shelter.schedule ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _scheduleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final success = await ref
        .read(shelterControllerProvider.notifier)
        .updateShelter({
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'address': _addressController.text.trim(),
          'city': _cityController.text.trim(),
          'phone': _phoneController.text.trim(),
          'schedule': _scheduleController.text.trim(),
        });

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado exitosamente'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar el perfil'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            controller: controller,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Text(
                    'Editar refugio',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),
              _ShelterField(
                controller: _nameController,
                label: 'Nombre del refugio',
                icon: Icons.home_outlined,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 12),
              _ShelterField(
                controller: _descriptionController,
                label: 'Descripción',
                icon: Icons.description_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              _ShelterField(
                controller: _addressController,
                label: 'Dirección',
                icon: Icons.location_on_outlined,
                helperText: 'Formato: Calle/Carrera Número, Ej: Carrera 56 134',
              ),
              const SizedBox(height: 12),
              _ShelterField(
                controller: _cityController,
                label: 'Ciudad',
                icon: Icons.location_city_outlined,
              ),
              const SizedBox(height: 12),
              _ShelterField(
                controller: _phoneController,
                label: 'Teléfono',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _ShelterField(
                controller: _scheduleController,
                label: 'Horario',
                icon: Icons.schedule_outlined,
                hintText: 'Ej: Lun-Sáb 9 AM - 6 PM',
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShelterField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;
  final TextInputType keyboardType;
  final String? hintText;
  final String? helperText;
  final String? Function(String?)? validator;

  const _ShelterField({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.hintText,
    this.helperText,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        helperText: helperText,
        helperMaxLines: 2,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}

// ── Modal Privacy & Safety ─────────────────────────────────────────────────

class _PrivacySafetyModal extends StatelessWidget {
  const _PrivacySafetyModal();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
              child: Row(
                children: [
                  const Text(
                    'Privacy & Safety',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: const [
                  _PrivacySection(
                    icon: Icons.storage_outlined,
                    title: 'Uso de tus datos personales',
                    content:
                        'Adoppi recopila únicamente la información necesaria para '
                        'brindarte una experiencia de adopción segura: nombre, correo '
                        'electrónico, ciudad e información del refugio. Tus datos se '
                        'almacenan de forma segura en servidores protegidos y nunca son '
                        'vendidos a terceros.',
                  ),
                  SizedBox(height: 16),
                  _PrivacySection(
                    icon: Icons.share_outlined,
                    title: 'Información compartida con adoptantes',
                    content:
                        'Cuando un adoptante inicia una conversación con tu refugio, '
                        'podrá ver el nombre del refugio y los mensajes que envíes. '
                        'No compartimos información adicional sin tu consentimiento explícito.',
                  ),
                  SizedBox(height: 16),
                  _PrivacySection(
                    icon: Icons.delete_outline,
                    title: 'Eliminación de cuenta y datos',
                    content:
                        'Puedes solicitar la eliminación de tu cuenta y todos tus datos '
                        'en cualquier momento escribiendo a adoppi0908@gmail.com. '
                        'Una vez confirmada la solicitud, tus datos serán eliminados '
                        'permanentemente en un plazo máximo de 7 días hábiles.',
                  ),
                  SizedBox(height: 16),
                  _PrivacySection(
                    icon: Icons.flag_outlined,
                    title: 'Reportar usuario sospechoso',
                    content:
                        'Si identificas un usuario con comportamiento sospechoso o '
                        'actitud inapropiada, repórtalo de inmediato a adoppi0908@gmail.com '
                        'con el asunto "Reporte de usuario". Nuestro equipo revisará '
                        'el caso en menos de 48 horas.',
                  ),
                  SizedBox(height: 16),
                  _PrivacySection(
                    icon: Icons.lock_outline,
                    title: 'Seguridad de tu cuenta',
                    content:
                        'Te recomendamos usar una contraseña única y segura para tu '
                        'cuenta de Adoppi. Si sospechas que alguien accedió a tu cuenta '
                        'sin autorización, cambia tu contraseña inmediatamente desde la '
                        'pantalla de inicio de sesión usando "¿Olvidaste tu contraseña?" '
                        'y contáctanos a adoppi0908@gmail.com.',
                  ),
                  SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _PrivacySection({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Modal Help & Support ───────────────────────────────────────────────────

class _HelpSupportModal extends StatelessWidget {
  const _HelpSupportModal();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
              child: Row(
                children: [
                  const Text(
                    'Help & Support',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: [
                  const _SectionLabel(label: 'Gestión de mascotas'),
                  const SizedBox(height: 12),
                  const _FaqTile(
                    question: '¿Cómo publico una mascota?',
                    answer:
                        'Desde tu panel de refugio, toca el botón "+" o "Agregar '
                        'mascota". Completa el formulario con fotos, nombre, edad, '
                        'raza, género, estado de salud y descripción. Una vez publicada, '
                        'aparecerá en el catálogo de Adoppi.',
                  ),
                  const _FaqTile(
                    question: '¿Cómo edito o elimino una mascota publicada?',
                    answer:
                        'Entra al perfil de la mascota desde tu panel de gestión y '
                        'toca el ícono de editar (lápiz) para modificar la información, '
                        'o el ícono de eliminar para retirarla del catálogo.',
                  ),
                  const _FaqTile(
                    question: '¿Cómo actualizo la información de mi refugio?',
                    answer:
                        'Desde tu perfil, toca el ícono de editar en la parte superior. '
                        'Podrás actualizar el nombre, descripción, dirección, horario, '
                        'teléfono y foto del refugio.',
                  ),
                  const SizedBox(height: 24),
                  const _SectionLabel(label: 'Mensajería'),
                  const SizedBox(height: 12),
                  const _FaqTile(
                    question: '¿Cómo funciona el chat con adoptantes?',
                    answer:
                        'Cuando un adoptante muestra interés en una mascota, se abre '
                        'automáticamente una conversación contigo. Recibirás una '
                        'notificación con cada nuevo mensaje. Puedes responder desde '
                        'la sección de Mensajes.',
                  ),
                  const _FaqTile(
                    question: '¿Puedo eliminar una conversación?',
                    answer:
                        'Sí. En la pantalla de mensajes, desliza la conversación hacia '
                        'la izquierda y toca el ícono de eliminar. La conversación '
                        'desaparecerá solo de tu lista; el adoptante conservará su copia.',
                  ),
                  const SizedBox(height: 24),
                  const _SectionLabel(label: 'Reportar un problema'),
                  const SizedBox(height: 12),
                  const _FaqTile(
                    question: '¿Cómo reporto un problema técnico?',
                    answer:
                        'Si encuentras un error o comportamiento inesperado en la app, '
                        'escríbenos a adoppi0908@gmail.com con el asunto "Problema '
                        'técnico". Describe lo que ocurrió, en qué pantalla y, si '
                        'puedes, adjunta una captura de pantalla.',
                  ),
                  const SizedBox(height: 24),
                  const _SectionLabel(label: 'Contacto'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.mail_outline,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Equipo Adoppi',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'adoppi0908@gmail.com',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Respondemos en menos de 48 horas',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
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
        letterSpacing: 0.3,
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _expanded
              ? AppColors.primary.withOpacity(0.4)
              : AppColors.divider,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _expanded
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: _expanded ? AppColors.primary : AppColors.textHint,
                      size: 22,
                    ),
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    widget.answer,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widgets reutilizables ──────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
