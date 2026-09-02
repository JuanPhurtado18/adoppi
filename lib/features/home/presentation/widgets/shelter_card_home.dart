import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shelter_panel/domain/shelter.dart';

class ShelterCardHome extends StatelessWidget {
  final Shelter shelter;
  final VoidCallback onTap;

  const ShelterCardHome({
    super.key,
    required this.shelter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: shelter.avatarUrl != null
                  ? CachedNetworkImage(
                      imageUrl: shelter.avatarUrl!,
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 100,
                        color: AppColors.divider,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 100,
                        color: AppColors.divider,
                        child: const Icon(
                          Icons.home,
                          color: AppColors.textHint,
                          size: 36,
                        ),
                      ),
                    )
                  : Container(
                      height: 100,
                      color: AppColors.divider,
                      child: const Icon(
                        Icons.home,
                        color: AppColors.textHint,
                        size: 36,
                      ),
                    ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shelter.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (shelter.city != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            shelter.city!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textHint,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
