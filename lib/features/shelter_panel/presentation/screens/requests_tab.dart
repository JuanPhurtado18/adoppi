import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/shelter_repository.dart';
import '../widgets/request_card.dart';

final shelterRequestsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, shelterId) async {
  final repo = ref.watch(shelterRepositoryProvider);
  return repo.getShelterRequests(shelterId);
});

class RequestsTab extends ConsumerWidget {
  final String shelterId;
  const RequestsTab({super.key, required this.shelterId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(shelterRequestsProvider(shelterId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: requestsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Text('Error al cargar solicitudes',
              style: TextStyle(color: AppColors.error)),
        ),
        data: (requests) => requests.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inbox_outlined,
                        size: 64, color: AppColors.textHint),
                    SizedBox(height: 16),
                    Text(
                      'No tienes solicitudes aún',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final request = requests[index];
                  return RequestCard(
                    request: request,
                    onUpdateStatus: (status) async {
                      await ref
                          .read(shelterRepositoryProvider)
                          .updateRequestStatus(
                            requestId: request['id'],
                            status: status,
                          );
                      ref.invalidate(shelterRequestsProvider(shelterId));
                    },
                  );
                },
              ),
      ),
    );
  }
}