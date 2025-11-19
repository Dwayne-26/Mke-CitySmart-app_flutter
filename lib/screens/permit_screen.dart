import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/permit.dart';
import '../providers/user_provider.dart';

class PermitScreen extends StatefulWidget {
  const PermitScreen({super.key});

  @override
  State<PermitScreen> createState() => _PermitScreenState();
}

class _PermitScreenState extends State<PermitScreen> {
  PermitType? _selectedType;
  final _dateFormat = DateFormat('MMM d, yyyy');
=======
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/permit.dart';
import '../widgets/app_drawer.dart';

class PermitScreen extends StatelessWidget {
  const PermitScreen({super.key});
>>>>>>> 2b87afb11f152c882e984ad699e63f1ed266df51

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();
    final permits = provider.permits;
    final filteredPermits = _selectedType == null
        ? permits
        : permits.where((permit) => permit.type == _selectedType).toList();
    final expiringSoon = permits
        .where((permit) => permit.isExpiringSoon)
        .toList();
    final activeCount = permits
        .where((permit) => permit.status == PermitStatus.active)
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFF003E29),
      appBar: AppBar(
        backgroundColor: const Color(0xFF003E29),
<<<<<<< HEAD
        title: const Text('Digital permits'),
        actions: [
          if (provider.isGuest)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Chip(
                label: Text('Guest mode'),
                avatar: Icon(Icons.visibility_outlined, size: 18),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPermitSheet(provider),
        label: const Text('Add permit'),
        icon: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PermitSummaryCard(
                activeCount: activeCount,
                expiringSoon: expiringSoon.length,
                offlineCount: permits
                    .where((permit) => permit.offlineAccess)
                    .length,
              ),
              const SizedBox(height: 16),
              _buildTypeFilters(),
              const SizedBox(height: 12),
              if (expiringSoon.isNotEmpty)
                _ExpiringSoonBanner(
                  expiring: expiringSoon,
                  dateFormat: _dateFormat,
                ),
              const SizedBox(height: 12),
              _PermitLegend(),
              const SizedBox(height: 8),
              _PermitFunctions(),
              const SizedBox(height: 12),
              if (filteredPermits.isEmpty)
                _EmptyState(onAddPermit: () => _showAddPermitSheet(provider))
              else
                ...filteredPermits.map(
                  (permit) => _PermitCard(
                    permit: permit,
                    dateFormat: _dateFormat,
                    onRenew: () async {
                      await provider.renewPermit(permit.id);
                      _showSnackBar(context, 'Permit renewed');
                    },
                    onToggleOffline: () =>
                        provider.toggleOfflineAccess(permit.id),
                    onChangeStatus: (status) =>
                        provider.updatePermitStatus(permit.id, status),
                    onManageVehicles: () =>
                        _showManageVehiclesSheet(provider, permit),
                    onToggleAutoRenew: (enabled) =>
                        provider.updateAutoRenew(permit.id, enabled),
                  ),
                ),
              const SizedBox(height: 72),
=======
        title: const Text('Permits', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddPermitDialog(context),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final permits = userProvider.permits;
          final activePermits = userProvider.getActivePermits();

          if (permits.isEmpty) {
            return _buildEmptyState(context);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Active Permits Section
                if (activePermits.isNotEmpty) ...[
                  const Text(
                    'Active Permits',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...activePermits.map(
                    (permit) => _buildPermitCard(context, permit, true),
                  ),
                  const SizedBox(height: 24),
                ],

                // All Permits Section
                const Text(
                  'All Permits',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...permits.map(
                  (permit) => _buildPermitCard(context, permit, false),
                ),

                const SizedBox(height: 100), // Space for FAB
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFFC107),
        foregroundColor: Colors.black,
        onPressed: () => _showAddPermitDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.credit_card, size: 80, color: Colors.white54),
            const SizedBox(height: 24),
            const Text(
              'No Permits Found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your first parking permit to get started',
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showAddPermitDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Permit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC107),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermitCard(BuildContext context, Permit permit, bool showQR) {
    final isExpired = permit.isExpired;
    final isActive = permit.isActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF006A3B) : Colors.grey.shade700,
        borderRadius: BorderRadius.circular(12),
        border: isExpired
            ? Border.all(color: Colors.red, width: 2)
            : isActive
            ? Border.all(color: const Color(0xFFFFC107), width: 2)
            : null,
      ),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: isActive ? const Color(0xFFFFC107) : Colors.grey,
              child: Icon(_getPermitTypeIcon(permit.type), color: Colors.black),
            ),
            title: Text(
              permit.permitNumber,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getPermitTypeName(permit.type),
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  permit.vehicle.licensePlate,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (permit.zone != null)
                  Text(
                    'Zone: ${permit.zone}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
              ],
            ),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isExpired
                        ? Colors.red
                        : isActive
                        ? Colors.green
                        : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isExpired
                        ? 'Expired'
                        : isActive
                        ? 'Active'
                        : 'Inactive',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Expires: ${_formatDate(permit.endDate)}',
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
            onTap: () => _showPermitDetails(context, permit),
          ),

          // QR Code Section (only for active permits or when requested)
          if (showQR && isActive) ...[
            const Divider(color: Colors.white24),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Show to parking enforcement',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(Icons.qr_code, size: 80, color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    permit.permitNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showPermitDetails(BuildContext context, Permit permit) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF003E29),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Permit Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // QR Code
              if (permit.isActive) ...[
                Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.qr_code,
                        size: 120,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Permit Information
              _buildDetailRow('Permit Number', permit.permitNumber),
              _buildDetailRow('Type', _getPermitTypeName(permit.type)),
              _buildDetailRow(
                'Status',
                permit.isActive
                    ? 'Active'
                    : permit.isExpired
                    ? 'Expired'
                    : 'Inactive',
              ),
              _buildDetailRow(
                'Vehicle',
                '${permit.vehicle.make} ${permit.vehicle.model} (${permit.vehicle.licensePlate})',
              ),
              if (permit.zone != null) _buildDetailRow('Zone', permit.zone!),
              _buildDetailRow('Start Date', _formatDate(permit.startDate)),
              _buildDetailRow('End Date', _formatDate(permit.endDate)),
              _buildDetailRow('Cost', '\$${permit.cost.toStringAsFixed(2)}'),

              if (!permit.isExpired) ...[
                _buildDetailRow(
                  'Time Remaining',
                  _formatDuration(permit.timeRemaining),
                ),
              ],

              const SizedBox(height: 24),

              // Action Buttons
              if (permit.isExpired || permit.timeRemaining.inDays < 30) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.go('/permits/renew/${permit.id}');
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Renew Permit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
>>>>>>> 2b87afb11f152c882e984ad699e63f1ed266df51
            ],
          ),
        ),
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildTypeFilters() {
    final chips = <Widget>[
      ChoiceChip(
        selected: _selectedType == null,
        label: const Text('All types'),
        onSelected: (_) => setState(() => _selectedType = null),
      ),
    ];

    chips.addAll(
      PermitType.values.map(
        (type) => ChoiceChip(
          selected: _selectedType == type,
          label: Text(_typeLabel(type)),
          onSelected: (_) => setState(() => _selectedType = type),
        ),
      ),
    );

    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  void _showAddPermitSheet(UserProvider provider) {
    final zoneController = TextEditingController(text: 'Zone 2 - Brady Street');
    final plateController = TextEditingController();
    PermitType selectedType = PermitType.residential;
    bool offline = true;
    bool autoRenew = true;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create permit',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PermitType>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Permit type'),
                  items: PermitType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(_typeLabel(type)),
                        ),
                      )
                      .toList(),
                  onChanged: (type) => setSheetState(
                    () => selectedType = type ?? PermitType.residential,
                  ),
                ),
                TextField(
                  controller: zoneController,
                  decoration: const InputDecoration(
                    labelText: 'Zone / neighborhood',
                  ),
                ),
                TextField(
                  controller: plateController,
                  decoration: const InputDecoration(
                    labelText: 'Primary vehicle plate',
                  ),
                ),
                SwitchListTile(
                  value: offline,
                  title: const Text('Make available offline'),
                  onChanged: (value) => setSheetState(() => offline = value),
                ),
                SwitchListTile(
                  value: autoRenew,
                  title: const Text('Enable auto renewal alerts'),
                  onChanged: (value) => setSheetState(() => autoRenew = value),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    final now = DateTime.now();
                    provider.addPermit(
                      Permit(
                        id: 'permit-${DateTime.now().microsecondsSinceEpoch}',
                        type: selectedType,
                        status: PermitStatus.active,
                        zone: zoneController.text.trim().isEmpty
                            ? 'General zone'
                            : zoneController.text.trim(),
                        startDate: now,
                        endDate: now.add(_durationFor(selectedType)),
                        vehicleIds: [
                          if (plateController.text.trim().isNotEmpty)
                            plateController.text.trim().toUpperCase(),
                        ],
                        qrCodeData:
                            '${_typeLabel(selectedType)}-${now.millisecondsSinceEpoch}',
                        offlineAccess: offline,
                        autoRenew: autoRenew,
                      ),
                    );
                    Navigator.pop(context);
                    _showSnackBar(context, 'Permit added');
                  },
                  child: const Text('Save permit'),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      zoneController.dispose();
      plateController.dispose();
    });
  }

  void _showManageVehiclesSheet(UserProvider provider, Permit permit) {
    final profileVehicles = provider.profile?.vehicles ?? [];
    final suggestions = <String>{
      for (final vehicle in profileVehicles) vehicle.licensePlate,
      ...permit.vehicleIds,
    }..removeWhere((plate) => plate.isEmpty);
    final controller = TextEditingController();
    final selected = permit.vehicleIds.toSet();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Vehicles for ${_typeLabel(permit.type)}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ...suggestions.map(
                  (plate) => CheckboxListTile(
                    value: selected.contains(plate),
                    title: Text(plate),
                    onChanged: (value) => setSheetState(() {
                      if (value == true) {
                        selected.add(plate);
                      } else {
                        selected.remove(plate);
                      }
                    }),
                  ),
                ),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(labelText: 'Add plate'),
                  onSubmitted: (value) => setSheetState(() {
                    final cleaned = value.trim().toUpperCase();
                    if (cleaned.isNotEmpty) {
                      selected.add(cleaned);
                      controller.clear();
                    }
                  }),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    provider.updatePermitVehicles(permit.id, selected.toList());
                    Navigator.pop(context);
                    _showSnackBar(context, 'Vehicles updated');
                  },
                  child: const Text('Save vehicles'),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(controller.dispose);
  }

  Duration _durationFor(PermitType type) {
    switch (type) {
      case PermitType.residential:
      case PermitType.visitor:
      case PermitType.business:
      case PermitType.handicap:
      case PermitType.monthly:
        return const Duration(days: 30);
      case PermitType.annual:
        return const Duration(days: 365);
      case PermitType.temporary:
        return const Duration(days: 7);
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PermitCard extends StatelessWidget {
  const _PermitCard({
    required this.permit,
    required this.dateFormat,
    required this.onRenew,
    required this.onToggleOffline,
    required this.onChangeStatus,
    required this.onManageVehicles,
    required this.onToggleAutoRenew,
  });

  final Permit permit;
  final DateFormat dateFormat;
  final VoidCallback onRenew;
  final VoidCallback onToggleOffline;
  final ValueChanged<PermitStatus> onChangeStatus;
  final VoidCallback onManageVehicles;
  final ValueChanged<bool> onToggleAutoRenew;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final totalDuration = permit.endDate.difference(permit.startDate).inSeconds;
    final double progress = totalDuration == 0
        ? 1.0
        : (now.isBefore(permit.startDate)
              ? 0
              : (now.isAfter(permit.endDate)
                    ? 1
                    : now.difference(permit.startDate).inSeconds /
                          totalDuration));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_typeLabel(permit.type)} permit',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                PopupMenuButton<PermitStatus>(
                  icon: Icon(Icons.flag, color: _statusColor(permit.status)),
                  onSelected: onChangeStatus,
                  itemBuilder: (context) => PermitStatus.values
                      .map(
                        (status) => PopupMenuItem(
                          value: status,
                          child: Text(status.name.toUpperCase()),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            Text(permit.zone, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Valid ${dateFormat.format(permit.startDate)} - ${dateFormat.format(permit.endDate)}',
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(value: progress, minHeight: 6),
                      const SizedBox(height: 4),
                      Text(
                        _expiryLabel(permit),
                        style: TextStyle(
                          color: permit.status == PermitStatus.expired
                              ? Colors.redAccent
                              : permit.isExpiringSoon
                              ? Colors.orange
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black12),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: QrImageView(
                    data: permit.qrCodeData,
                    size: 90,
                    backgroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final plate in permit.vehicleIds)
                  Chip(
                    avatar: const Icon(Icons.directions_car, size: 18),
                    label: Text(plate),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add),
                  label: const Text('Add vehicle'),
                  onPressed: onManageVehicles,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: [
                TextButton.icon(
                  onPressed: onRenew,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Renew'),
                ),
                TextButton.icon(
                  onPressed: onToggleOffline,
                  icon: Icon(
                    permit.offlineAccess ? Icons.download_done : Icons.download,
                  ),
                  label: Text(
                    permit.offlineAccess ? 'Offline ready' : 'Save offline',
                  ),
                ),
                TextButton.icon(
                  onPressed: () => onToggleAutoRenew(!permit.autoRenew),
                  icon: Icon(
                    permit.autoRenew
                        ? Icons.notifications_active
                        : Icons.notifications_paused,
                  ),
                  label: Text(permit.autoRenew ? 'Alerts on' : 'Alerts off'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _expiryLabel(Permit permit) {
    final now = DateTime.now();
    if (permit.status == PermitStatus.expired || now.isAfter(permit.endDate)) {
      final daysAgo = now.difference(permit.endDate).inDays.abs();
      return 'Expired $daysAgo day${daysAgo == 1 ? '' : 's'} ago';
    }
    final days = permit.endDate.difference(now).inDays;
    return 'Expires in $days day${days == 1 ? '' : 's'}';
  }

  static Color _statusColor(PermitStatus status) {
    switch (status) {
      case PermitStatus.active:
        return Colors.green;
      case PermitStatus.expired:
        return Colors.redAccent;
      case PermitStatus.inactive:
        return Colors.grey;
    }
  }
}

class _PermitSummaryCard extends StatelessWidget {
  const _PermitSummaryCard({
    required this.activeCount,
    required this.expiringSoon,
    required this.offlineCount,
  });

  final int activeCount;
  final int expiringSoon;
  final int offlineCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SummaryMetric(label: 'Active', value: activeCount.toString()),
            _SummaryMetric(label: 'Expiring', value: expiringSoon.toString()),
            _SummaryMetric(label: 'Offline', value: offlineCount.toString()),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}

class _PermitLegend extends StatelessWidget {
  final Map<PermitType, String> _descriptions = const {
    PermitType.residential: 'Neighborhood parking for residents',
    PermitType.visitor: 'Short-term credentials for guests',
    PermitType.business: 'Fleet and delivery coverage',
    PermitType.handicap: 'City-wide ADA accommodations',
    PermitType.monthly: 'Garage or lot subscriptions',
    PermitType.annual: 'Year-long municipal access',
    PermitType.temporary: 'Events, construction, pop-ups',
  };

  _PermitLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: const Text('Permit type overview'),
        children: _descriptions.entries
            .map(
              (entry) => ListTile(
                leading: Icon(
                  Icons.local_parking,
                  color: _typeColor(entry.key),
                ),
                title: Text(_typeLabel(entry.key)),
                subtitle: Text(entry.value),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _PermitFunctions extends StatelessWidget {
  final List<Map<String, dynamic>> _functions = const [
    {
      'icon': Icons.qr_code_2,
      'title': 'Digital permit display',
      'subtitle': 'Instant QR proof for officers and attendants.',
    },
    {
      'icon': Icons.autorenew,
      'title': 'Renewal & notifications',
      'subtitle': 'Auto-renew toggles, push reminders, expiry alerts.',
    },
    {
      'icon': Icons.directions_car,
      'title': 'Multi-vehicle support',
      'subtitle': 'Assign multiple vehicles or visitor plates per permit.',
    },
    {
      'icon': Icons.public,
      'title': 'Zone-based control',
      'subtitle': 'Each permit is scoped to a zone for compliance.',
    },
    {
      'icon': Icons.wifi_off,
      'title': 'Offline pass access',
      'subtitle': 'Cache permits so they load even without a signal.',
    },
  ];

  _PermitFunctions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _functions
          .map(
            (item) => Card(
              child: ListTile(
                leading: Icon(item['icon'] as IconData),
                title: Text(item['title'] as String),
                subtitle: Text(item['subtitle'] as String),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ExpiringSoonBanner extends StatelessWidget {
  const _ExpiringSoonBanner({required this.expiring, required this.dateFormat});

  final List<Permit> expiring;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Renewal reminders',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            ...expiring.map(
              (permit) => Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.orange),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${_typeLabel(permit.type)} expires ${dateFormat.format(permit.endDate)}',
                    ),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddPermit});

  final VoidCallback onAddPermit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.verified, size: 56, color: Colors.white),
            const SizedBox(height: 12),
            const Text(
              'No permits to show',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Add a permit to manage digital passes and QR codes.'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onAddPermit,
              child: const Text('Create permit'),
            ),
          ],
        ),
      ),
    );
  }
}

String _typeLabel(PermitType type) {
  switch (type) {
    case PermitType.residential:
      return 'Residential';
    case PermitType.visitor:
      return 'Visitor';
    case PermitType.business:
      return 'Business';
    case PermitType.handicap:
      return 'Handicap';
    case PermitType.monthly:
      return 'Monthly';
    case PermitType.annual:
      return 'Annual';
    case PermitType.temporary:
      return 'Temporary';
  }
}

Color _typeColor(PermitType type) {
  switch (type) {
    case PermitType.residential:
      return Colors.blueAccent;
    case PermitType.visitor:
      return Colors.purpleAccent;
    case PermitType.business:
      return Colors.deepOrange;
    case PermitType.handicap:
      return Colors.indigo;
    case PermitType.monthly:
      return Colors.teal;
    case PermitType.annual:
      return Colors.green;
    case PermitType.temporary:
      return Colors.redAccent;
=======
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddPermitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF003E29),
        title: const Text(
          'Add New Permit',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This feature would connect to your city\'s permit system to add or renew parking permits.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Feature coming soon!'),
                  backgroundColor: Color(0xFFFFC107),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC107),
              foregroundColor: Colors.black,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  IconData _getPermitTypeIcon(PermitType type) {
    switch (type) {
      case PermitType.residential:
        return Icons.home;
      case PermitType.visitor:
        return Icons.person;
      case PermitType.business:
        return Icons.business;
      case PermitType.handicap:
        return Icons.accessible;
      case PermitType.monthly:
        return Icons.calendar_month;
      case PermitType.annual:
        return Icons.calendar_today;
      case PermitType.temporary:
        return Icons.schedule;
    }
  }

  String _getPermitTypeName(PermitType type) {
    switch (type) {
      case PermitType.residential:
        return 'Residential';
      case PermitType.visitor:
        return 'Visitor';
      case PermitType.business:
        return 'Business';
      case PermitType.handicap:
        return 'Handicap';
      case PermitType.monthly:
        return 'Monthly';
      case PermitType.annual:
        return 'Annual';
      case PermitType.temporary:
        return 'Temporary';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
    } else {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
    }
>>>>>>> 2b87afb11f152c882e984ad699e63f1ed266df51
  }
}
