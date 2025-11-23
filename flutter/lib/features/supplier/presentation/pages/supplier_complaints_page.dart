import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../services/api_service.dart';
import '../../data/supplier_api_service.dart';
import '../../data/supplier_models.dart';
import 'supplier_home_shell.dart';

class SupplierComplaintsPage extends StatefulWidget {
  const SupplierComplaintsPage({super.key});

  @override
  State<SupplierComplaintsPage> createState() => _SupplierComplaintsPageState();
}

class _SupplierComplaintsPageState extends State<SupplierComplaintsPage> {
  final SupplierApiService _api = SupplierApiService();
  late Future<List<SupplierComplaint>> _complaintsFuture;
  List<SupplierComplaint> _complaints = [];
  _ComplaintFilter _filter = _ComplaintFilter.all;

  @override
  void initState() {
    super.initState();
    _complaintsFuture = _loadComplaints();
  }

  Future<List<SupplierComplaint>> _loadComplaints() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) {
      throw const AuthException('You are not authenticated.');
    }
    final complaints = await _api.fetchComplaints(token: token);
    _complaints = complaints;
    return complaints;
  }

  Future<void> _refresh() async {
    setState(() {
      _complaintsFuture = _loadComplaints();
    });
    await _complaintsFuture;
  }

  void _showSnack(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
        ),
      );
  }

  Future<bool> _updateComplaintStatus(int complaintId, String newStatus) async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) {
      _showSnack('You are not authenticated.');
      return false;
    }

    try {
      await _api.updateComplaintStatus(
        token: token,
        complaintId: complaintId,
        newStatus: newStatus,
      );
      await _refresh();
      _showSnack(
        'Complaint #$complaintId updated to ${_statusLabel(newStatus)}.',
        backgroundColor: Colors.green,
      );
      return true;
    } on ApiServiceException catch (e) {
      _showSnack(e.message);
      return false;
    } catch (e) {
      _showSnack(e.toString());
      return false;
    }
  }

  List<SupplierComplaint> get _filteredComplaints {
    switch (_filter) {
      case _ComplaintFilter.open:
        return _complaints.where((c) => c.isOpen).toList();
      case _ComplaintFilter.inProgress:
        return _complaints.where((c) => c.isInProgress).toList();
      case _ComplaintFilter.resolved:
        return _complaints.where((c) => c.isResolved).toList();
      case _ComplaintFilter.all:
        return _complaints;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SupplierHomeShell(
      title: 'Complaints',
      section: SupplierSection.complaints,
      child: Column(
        children: [
          const SizedBox(height: 16),
          _ComplaintTabs(
            currentFilter: _filter,
            onChanged: (value) => setState(() => _filter = value),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<SupplierComplaint>>(
              future: _complaintsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _ErrorState(
                    message: snapshot.error.toString(),
                    onRetry: _refresh,
                  );
                }
                if (_complaints.isEmpty) {
                  return const _EmptyState(
                    message: 'No complaints have been logged yet.',
                  );
                }
                final complaints = _filteredComplaints;
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: complaints.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final complaint = complaints[index];
                      return _ComplaintCard(
                        complaint: complaint,
                        onView: () => _openDetails(complaint),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'open':
        return 'Open';
      case 'in_progress':
        return 'In progress';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      default:
        return status;
    }
  }

  void _openDetails(SupplierComplaint complaint) {
    const statuses = ['open', 'in_progress', 'resolved', 'closed'];
    String selectedStatus = complaint.status;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      builder: (_) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              complaint.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3E46),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Complaint #${complaint.id}',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(
                    icon: Icons.receipt_long,
                    label: 'Order',
                    value: complaint.orderId != null
                        ? '#${complaint.orderId}'
                        : 'Not linked',
                  ),
                  _DetailRow(
                    icon: Icons.flag_outlined,
                    label: 'Status',
                    value: _statusLabel(selectedStatus),
                  ),
                  if (complaint.severity != null)
                    _DetailRow(
                      icon: Icons.warning_amber_rounded,
                      label: 'Severity',
                      value: complaint.severity!,
                    ),
                  if (complaint.complaintType != null)
                    _DetailRow(
                      icon: Icons.category_outlined,
                      label: 'Type',
                      value: _complaintTypeLabel(complaint.complaintType!),
                    ),
                  if (complaint.escalationLevel != null)
                    _DetailRow(
                      icon: Icons.trending_up,
                      label: 'Escalation Level',
                      value: _escalationLevelLabel(complaint.escalationLevel!),
                    ),
                  const SizedBox(height: 12),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E3E46),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      complaint.description,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Update status',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E3E46),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    items: statuses
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(_statusLabel(status)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setModalState(() => selectedStatus = value);
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isSaving || selectedStatus == complaint.status
                          ? null
                          : () async {
                              setModalState(() => isSaving = true);
                              final success = await _updateComplaintStatus(
                                complaint.id,
                                selectedStatus,
                              );
                              if (!success) {
                                setModalState(() => isSaving = false);
                                return;
                              }
                              if (Navigator.of(modalContext).canPop()) {
                                Navigator.of(modalContext).pop();
                              }
                            },
                      icon: isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        isSaving ? 'Saving...' : 'Save changes',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF21545F),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 46),
                      ),
                    ),
                  ),
                  if (complaint.canEscalate) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showEscalateDialog(complaint),
                        icon: const Icon(Icons.arrow_upward),
                        label: const Text('Escalate to Manager'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                          side: const BorderSide(color: Colors.orange),
                          minimumSize: const Size(double.infinity, 46),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _complaintTypeLabel(String type) {
    switch (type) {
      case 'product':
        return 'Product quality';
      case 'delivery':
        return 'Delivery issue';
      case 'billing':
        return 'Billing/price';
      case 'service':
        return 'Service/communication';
      case 'other':
        return 'Other';
      default:
        return type;
    }
  }

  String _escalationLevelLabel(String level) {
    switch (level) {
      case 'sales':
        return 'Sales Representative';
      case 'manager':
        return 'Manager';
      case 'owner':
        return 'Owner';
      default:
        return level;
    }
  }

  void _showEscalateDialog(SupplierComplaint complaint) {
    final TextEditingController reasonController = TextEditingController();
    bool isEscalating = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Escalate Complaint'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This will escalate the complaint to a higher level.',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Reason for escalation',
                      hintText: 'Explain why this needs escalation...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    enabled: !isEscalating,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isEscalating ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isEscalating
                      ? null
                      : () async {
                          if (reasonController.text.trim().isEmpty) {
                            _showSnack('Please provide a reason for escalation');
                            return;
                          }

                          setDialogState(() => isEscalating = true);

                          final auth = context.read<AuthProvider>();
                          final token = auth.token;
                          if (token == null) {
                            _showSnack('You are not authenticated.');
                            setDialogState(() => isEscalating = false);
                            return;
                          }

                          try {
                            await _api.escalateComplaint(
                              token: token,
                              complaintId: complaint.id,
                              reason: reasonController.text.trim(),
                            );
                            await _refresh();
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            _showSnack(
                              'Complaint #${complaint.id} escalated successfully.',
                              backgroundColor: Colors.green,
                            );
                          } on ApiServiceException catch (e) {
                            _showSnack(e.message);
                            setDialogState(() => isEscalating = false);
                          } catch (e) {
                            _showSnack(e.toString());
                            setDialogState(() => isEscalating = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: isEscalating
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Escalate'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ComplaintTabs extends StatelessWidget {
  const _ComplaintTabs({
    required this.currentFilter,
    required this.onChanged,
  });

  final _ComplaintFilter currentFilter;
  final ValueChanged<_ComplaintFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    const tabs = [
      (_ComplaintFilter.all, 'All'),
      (_ComplaintFilter.open, 'Open'),
      (_ComplaintFilter.inProgress, 'In progress'),
      (_ComplaintFilter.resolved, 'Resolved'),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFDDE8EB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: tabs.map((entry) {
          final isSelected = currentFilter == entry.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(entry.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  entry.$2,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFF21545F)
                        : Colors.black.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  const _ComplaintCard({required this.complaint, required this.onView});

  final SupplierComplaint complaint;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFA7E1D5),
                child: Text(
                  complaint.title.substring(0, 1),
                  style: const TextStyle(
                    color: Color(0xFF21545F),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complaint.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E3E46),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Order #${complaint.orderId ?? '—'}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusChip(complaint: complaint),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            complaint.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.black87, height: 1.4),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onView,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF21545F),
              side: const BorderSide(color: Color(0xFF21545F)),
              minimumSize: const Size(double.infinity, 44),
            ),
            child: const Text('View complaint'),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.complaint});

  final SupplierComplaint complaint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: complaint.statusColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        complaint.statusLabel,
        style: TextStyle(
          color: complaint.statusColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black54),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(color: Colors.black54),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

enum _ComplaintFilter { all, open, inProgress, resolved }
