import 'package:easyedubd_app/features/presentation/screens/admin/promotion_course_assignment_screen.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/promotion.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/repository/promotion_repository.dart';
import 'package:easyedubd_app/shared/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PromotionManagementScreen extends ConsumerStatefulWidget {
  const PromotionManagementScreen({super.key});

  @override
  ConsumerState<PromotionManagementScreen> createState() =>
      _PromotionManagementScreenState();
}

class _PromotionManagementScreenState
    extends ConsumerState<PromotionManagementScreen> {
  late Future<List<Promotion>> _promotionsFuture;

  @override
  void initState() {
    super.initState();
    _promotionsFuture = ref.read(promotionRepositoryProvider).getAllPromotions();
  }

  Future<void> _refresh() async {
    setState(() {
      _promotionsFuture = ref.read(promotionRepositoryProvider).getAllPromotions();
    });
  }

  Future<void> _showPromotionDialog([Promotion? promotion]) async {
    final isEdit = promotion != null;
    final nameController = TextEditingController(text: promotion?.name ?? '');
    final discountValueController = TextEditingController(
      text: promotion?.discountValue.toString() ?? '',
    );
    String discountType = promotion?.discountType ?? 'percentage';
    bool isActive = promotion?.isActive ?? true;
    DateTime? startsAt = promotion?.startsAt;
    DateTime? endsAt = promotion?.endsAt;
    String? errorText;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Promotion' : 'Create Promotion'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      errorText!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Promotion Name'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: discountType,
                  decoration: const InputDecoration(labelText: 'Discount Type'),
                  items: const [
                    DropdownMenuItem(
                        value: 'percentage', child: Text('Percentage')),
                    DropdownMenuItem(value: 'fixed', child: Text('Fixed Amount')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => discountType = value);
                    }
                  },
                ),
                TextField(
                  controller: discountValueController,
                  decoration: InputDecoration(
                    labelText: discountType == 'percentage'
                        ? 'Discount Percentage (%)'
                        : 'Discount Amount (৳)',
                  ),
                  keyboardType: TextInputType.number,
                ),
                SwitchListTile(
                  title: const Text('Active'),
                  subtitle: const Text('Enable this promotion'),
                  value: isActive,
                  onChanged: (value) {
                    setDialogState(() => isActive = value);
                  },
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    final now = DateTime.now();
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startsAt ?? now,
                      firstDate: now.subtract(const Duration(days: 1)),
                      lastDate: now.add(const Duration(days: 365)),
                    );
                    if (date != null && dialogContext.mounted) {
                      final time = await showTimePicker(
                        context: dialogContext,
                        initialTime: TimeOfDay.fromDateTime(
                          startsAt ?? now,
                        ),
                      );
                      if (time != null) {
                        setDialogState(() {
                          startsAt = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    startsAt == null
                        ? 'Set Start Date'
                        : 'Start: ${startsAt!.toLocal()}'.split('.')[0],
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final now = DateTime.now();
                    final date = await showDatePicker(
                      context: context,
                      initialDate: endsAt ?? now.add(const Duration(days: 7)),
                      firstDate: now.subtract(const Duration(days: 1)),
                      lastDate: now.add(const Duration(days: 365)),
                    );
                    if (date != null && dialogContext.mounted) {
                      final time = await showTimePicker(
                        context: dialogContext,
                        initialTime: TimeOfDay.fromDateTime(
                          endsAt ?? now.add(const Duration(days: 7)),
                        ),
                      );
                      if (time != null) {
                        setDialogState(() {
                          endsAt = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                  icon: const Icon(Icons.event),
                  label: Text(
                    endsAt == null
                        ? 'Set End Date'
                        : 'End: ${endsAt!.toLocal()}'.split('.')[0],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final discountText = discountValueController.text.trim();
                final discount = double.tryParse(discountText);

                if (name.isEmpty) {
                  setDialogState(() => errorText = 'Name is required');
                  return;
                }
                if (discount == null || discount <= 0) {
                  setDialogState(() => errorText = 'Invalid discount value');
                  return;
                }

                try {
                  final payload = {
                    'name': name,
                    'discount_type': discountType,
                    'discount_value': discount,
                    'is_active': isActive,
                    if (startsAt != null)
                      'starts_at': startsAt!.toUtc().toIso8601String(),
                    if (endsAt != null)
                      'ends_at': endsAt!.toUtc().toIso8601String(),
                  };

                  if (isEdit) {
                    await ref
                        .read(promotionRepositoryProvider)
                        .updatePromotion(
                          promotion.id,
                          payload,
                        );
                  } else {
                    await ref
                        .read(promotionRepositoryProvider)
                        .createPromotion(payload);
                  }
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop(true);
                } catch (e) {
                  if (dialogContext.mounted) {
                    setDialogState(() => errorText = 'Error: $e');
                  }
                }
              },
              child: Text(isEdit ? 'Save' : 'Create'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEdit ? 'Promotion updated' : 'Promotion created')),
      );
    }
  }

  Future<void> _deletePromotion(Promotion promotion) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Promotion',
      content: 'Are you sure you want to delete "${promotion.name}"?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(promotionRepositoryProvider)
          .removePromotionAssignments(promotion.id);
      await ref
          .read(promotionRepositoryProvider)
          .deletePromotion(promotion.id);
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Promotion deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _assignCourses(Promotion promotion) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => PromotionCourseAssignmentScreen(
          promotionId: promotion.id,
          promotionName: promotion.name,
        ),
      ),
    );

    if (result == true && mounted) {
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Promotion courses updated')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promotion Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create Promotion',
            onPressed: () => _showPromotionDialog(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Promotion>>(
          future: _promotionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text('Error: ${snapshot.error}'),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final promotions = snapshot.data ?? const [];

            if (promotions.isEmpty) {
              return const Center(
                child: Text('No promotions found.'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: promotions.length,
              itemBuilder: (context, index) {
                final promotion = promotions[index];
                final isActiveNow = promotion.isActiveFor(DateTime.now());
                final isExpired = promotion.isExpired;
                final isUpcoming = promotion.isUpcoming;
                final statusLabel = isExpired
                    ? 'Expired'
                    : isUpcoming
                        ? 'Upcoming'
                        : isActiveNow
                            ? 'Active'
                            : 'Inactive';
                final statusColor = isExpired
                    ? Colors.red
                    : isUpcoming
                        ? Colors.orange
                        : isActiveNow
                            ? Colors.green
                            : Colors.grey;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => _assignCourses(promotion),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  promotion.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: statusColor),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${promotion.discountType == 'percentage' ? '${promotion.discountValue}%' : '৳${promotion.discountValue.toStringAsFixed(0)}'} off',
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(
                                promotion.formattedStartDate,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(Icons.event, size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(
                                promotion.formattedEndDate,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            promotion.timeRemainingText,
                            style: TextStyle(
                              fontSize: 12,
                              color: isExpired ? Colors.red : Colors.grey[700],
                              fontWeight: isExpired ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 8),
                          FutureBuilder<int>(
                            future: ref
                                .read(promotionRepositoryProvider)
                                .getCourseIdsForPromotion(promotion.id)
                                .then((ids) => ids.length),
                            builder: (context, snapshot) {
                              final count = snapshot.data ?? 0;
                              return Text(
                                '$count course${count == 1 ? '' : 's'} assigned',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {},
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _showPromotionDialog(promotion),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deletePromotion(promotion),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
