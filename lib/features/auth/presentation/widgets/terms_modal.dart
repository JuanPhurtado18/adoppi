import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class TermsModal extends StatelessWidget {
  const TermsModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TermsModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Términos y Condiciones',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Contenido
          const Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TermsSection(
                    title: '1. Aceptación de los Términos',
                    content:
                        'Al acceder y utilizar Adoppi, usted acepta estar vinculado por estos Términos y Condiciones. Si no está de acuerdo con alguna parte de estos términos, no podrá acceder al servicio.',
                  ),
                  _TermsSection(
                    title: '2. Descripción del Servicio',
                    content:
                        'Adoppi es una plataforma digital que conecta refugios de animales con personas interesadas en adoptar mascotas en Cali, Colombia. No somos un refugio ni una tienda de mascotas; actuamos como intermediario entre el usuario y los refugios registrados.',
                  ),
                  _TermsSection(
                    title: '3. Responsabilidades del Usuario',
                    content:
                        'El usuario se compromete a proporcionar información veraz y actualizada durante el registro. Queda prohibido el uso de la plataforma para fines distintos a la adopción responsable de animales.',
                  ),
                  _TermsSection(
                    title: '4. Responsabilidades del Refugio',
                    content:
                        'Los refugios registrados son responsables de la veracidad de la información publicada sobre las mascotas. Adoppi no se hace responsable por información incorrecta proporcionada por los refugios.',
                  ),
                  _TermsSection(
                    title: '5. Privacidad y Datos',
                    content:
                        'La información personal recopilada será utilizada únicamente para el funcionamiento de la plataforma. No compartimos datos personales con terceros sin consentimiento expreso del usuario.',
                  ),
                  _TermsSection(
                    title: '6. Adopción Responsable',
                    content:
                        'Adoppi promueve la adopción responsable. Los usuarios se comprometen a proporcionar un hogar digno y amoroso a las mascotas adoptadas. El proceso de adopción final queda bajo responsabilidad del refugio correspondiente.',
                  ),
                ],
              ),
            ),
          ),
          // Botón cerrar
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  final String title;
  final String content;

  const _TermsSection({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}