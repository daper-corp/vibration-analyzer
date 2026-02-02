import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_theme.dart';
import '../constants/app_constants.dart';
import '../models/measurement.dart';
import '../providers/app_provider.dart';

/// Equipment management screen with hierarchical structure
class EquipmentScreen extends StatelessWidget {
  const EquipmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: AppTheme.primaryDark,
          appBar: AppBar(
            title: const Text('Equipment'),
            backgroundColor: AppTheme.primaryDark,
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showAddEquipmentDialog(context, provider),
              ),
            ],
          ),
          body: provider.equipment.isEmpty
              ? _buildEmptyState(context, provider)
              : _buildEquipmentList(context, provider),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, AppProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.precision_manufacturing,
              color: AppTheme.textMuted,
              size: 80,
            ),
            const SizedBox(height: 24),
            const Text(
              'No Equipment',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your first piece of equipment to start monitoring vibration levels.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showAddEquipmentDialog(context, provider),
              icon: const Icon(Icons.add),
              label: const Text('Add Equipment'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentList(BuildContext context, AppProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.equipment.length,
      itemBuilder: (context, index) {
        final equipment = provider.equipment[index];
        return _EquipmentCard(
          equipment: equipment,
          provider: provider,
          onTap: () => _showEquipmentDetails(context, equipment, provider),
        );
      },
    );
  }

  void _showAddEquipmentDialog(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.primaryMid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AddEquipmentSheet(provider: provider),
    );
  }

  void _showEquipmentDetails(
    BuildContext context,
    Equipment equipment,
    AppProvider provider,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _EquipmentDetailScreen(
          equipment: equipment,
          provider: provider,
        ),
      ),
    );
  }
}

class _EquipmentCard extends StatelessWidget {
  final Equipment equipment;
  final AppProvider provider;
  final VoidCallback onTap;

  const _EquipmentCard({
    required this.equipment,
    required this.provider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.precision_manufacturing,
                      color: AppTheme.accentBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          equipment.name,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${equipment.machineClass} • ${equipment.nominalRpm?.toStringAsFixed(0) ?? "N/A"} RPM',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppTheme.textMuted,
                  ),
                ],
              ),
              if (equipment.description != null) ...[
                const SizedBox(height: 12),
                Text(
                  equipment.description!,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.business,
                    equipment.manufacturer ?? 'N/A',
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.tag,
                    equipment.model ?? 'N/A',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.textMuted),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddEquipmentSheet extends StatefulWidget {
  final AppProvider provider;

  const _AddEquipmentSheet({required this.provider});

  @override
  State<_AddEquipmentSheet> createState() => _AddEquipmentSheetState();
}

class _AddEquipmentSheetState extends State<_AddEquipmentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rpmController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _modelController = TextEditingController();
  final _serialController = TextEditingController();
  String _machineClass = 'Class II';

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _rpmController.dispose();
    _manufacturerController.dispose();
    _modelController.dispose();
    _serialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Equipment',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Equipment Name *',
                  hintText: 'e.g., Cooling Water Pump #1',
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'e.g., 75kW centrifugal pump',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _machineClass,
                decoration: const InputDecoration(
                  labelText: 'Machine Class (ISO 10816)',
                ),
                dropdownColor: AppTheme.surfaceLight,
                items: [
                  AppConstants.machineClass1,
                  AppConstants.machineClass2,
                  AppConstants.machineClass3,
                  AppConstants.machineClass4,
                ].map((cls) {
                  return DropdownMenuItem(
                    value: cls,
                    child: Text(cls),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _machineClass = value!);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _rpmController,
                decoration: const InputDecoration(
                  labelText: 'Nominal RPM',
                  hintText: 'e.g., 1480',
                  suffixText: 'RPM',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _manufacturerController,
                      decoration: const InputDecoration(
                        labelText: 'Manufacturer',
                        hintText: 'e.g., KSB',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _modelController,
                      decoration: const InputDecoration(
                        labelText: 'Model',
                        hintText: 'e.g., Etanorm',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _serialController,
                decoration: const InputDecoration(
                  labelText: 'Serial Number',
                  hintText: 'e.g., SN-2024-001',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveEquipment,
                  child: const Text('Add Equipment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveEquipment() {
    if (_formKey.currentState!.validate()) {
      final equipment = Equipment(
        id: const Uuid().v4(),
        name: _nameController.text,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        machineClass: _machineClass,
        nominalRpm: _rpmController.text.isNotEmpty
            ? double.tryParse(_rpmController.text)
            : null,
        manufacturer: _manufacturerController.text.isNotEmpty
            ? _manufacturerController.text
            : null,
        model: _modelController.text.isNotEmpty ? _modelController.text : null,
        serialNumber:
            _serialController.text.isNotEmpty ? _serialController.text : null,
        createdAt: DateTime.now(),
      );

      widget.provider.addEquipment(equipment);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Equipment added successfully'),
          backgroundColor: AppTheme.statusGood,
        ),
      );
    }
  }
}

class _EquipmentDetailScreen extends StatelessWidget {
  final Equipment equipment;
  final AppProvider provider;

  const _EquipmentDetailScreen({
    required this.equipment,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    // Manually load locations for this equipment
    provider.selectEquipment(equipment);

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(equipment.name),
        backgroundColor: AppTheme.primaryDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location),
            onPressed: () => _showAddLocationDialog(context),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _confirmDelete(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: AppTheme.statusUnacceptable),
                    SizedBox(width: 8),
                    Text('Delete Equipment'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Equipment info card
                _buildInfoCard(),
                const SizedBox(height: 24),

                // Locations section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Measurement Locations',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showAddLocationDialog(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (provider.locations.isEmpty)
                  _buildEmptyLocations(context)
                else
                  ...provider.locations.map((loc) => _LocationCard(
                        location: loc,
                        provider: provider,
                      )),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.precision_manufacturing,
                    color: AppTheme.accentBlue,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentBlue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          equipment.machineClass,
                          style: const TextStyle(
                            color: AppTheme.accentBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (equipment.nominalRpm != null)
                        Text(
                          'Nominal Speed: ${equipment.nominalRpm!.toStringAsFixed(0)} RPM',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (equipment.description != null) ...[
              const SizedBox(height: 16),
              Text(
                equipment.description!,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Divider(color: AppTheme.primaryLight),
            const SizedBox(height: 12),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _buildDetailItem('Manufacturer', equipment.manufacturer ?? 'N/A'),
                _buildDetailItem('Model', equipment.model ?? 'N/A'),
                _buildDetailItem('Serial', equipment.serialNumber ?? 'N/A'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyLocations(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.location_off,
            color: AppTheme.textMuted,
            size: 48,
          ),
          const SizedBox(height: 12),
          const Text(
            'No measurement locations',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Add locations like bearing housings or motor ends',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showAddLocationDialog(context),
            icon: const Icon(Icons.add_location, size: 18),
            label: const Text('Add Location'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentBlue,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddLocationDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.primaryMid,
        title: const Text('Add Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Location Name *',
                hintText: 'e.g., Drive End Bearing',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'e.g., Motor side bearing housing',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final location = MeasurementLocation(
                  id: const Uuid().v4(),
                  equipmentId: equipment.id,
                  name: nameController.text,
                  description: descController.text.isNotEmpty
                      ? descController.text
                      : null,
                );
                provider.addLocation(location);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.primaryMid,
        title: const Text('Delete Equipment'),
        content: Text(
          'Are you sure you want to delete "${equipment.name}"?\n\nThis will also delete all locations, points, and measurement history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteEquipment(equipment.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to equipment list
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusUnacceptable,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final MeasurementLocation location;
  final AppProvider provider;

  const _LocationCard({
    required this.location,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    provider.selectLocation(location);
    final points = provider.points;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: const Icon(
          Icons.location_on,
          color: AppTheme.accentGreen,
        ),
        title: Text(
          location.name,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: location.description != null
            ? Text(
                location.description!,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                ),
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Measurement Points',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showAddPointDialog(context),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.accentBlue,
                      ),
                    ),
                  ],
                ),
                if (points.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No measurement points added',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  )
                else
                  ...points.map((point) => _buildPointTile(context, point)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointTile(BuildContext context, MeasurementPoint point) {
    return ListTile(
      dense: true,
      leading: Icon(
        _getDirectionIcon(point.direction),
        color: AppTheme.accentCyan,
        size: 20,
      ),
      title: Text(
        point.name,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        '${point.direction}${point.bearingType != null ? " • ${point.bearingType}" : ""}',
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 12,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(
          Icons.delete_outline,
          color: AppTheme.textMuted,
          size: 20,
        ),
        onPressed: () => _confirmDeletePoint(context, point),
      ),
    );
  }

  IconData _getDirectionIcon(String direction) {
    switch (direction) {
      case 'Horizontal':
        return Icons.swap_horiz;
      case 'Vertical':
        return Icons.swap_vert;
      case 'Axial':
        return Icons.sync_alt;
      default:
        return Icons.sensors;
    }
  }

  void _showAddPointDialog(BuildContext context) {
    final nameController = TextEditingController();
    String direction = 'Horizontal';
    String? bearingType;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.primaryMid,
          title: const Text('Add Measurement Point'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Point Name *',
                  hintText: 'e.g., 1H, 1V, 1A',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: direction,
                decoration: const InputDecoration(
                  labelText: 'Direction',
                ),
                dropdownColor: AppTheme.surfaceLight,
                items: ['Horizontal', 'Vertical', 'Axial'].map((d) {
                  return DropdownMenuItem(value: d, child: Text(d));
                }).toList(),
                onChanged: (value) => setState(() => direction = value!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: bearingType,
                decoration: const InputDecoration(
                  labelText: 'Bearing Type (Optional)',
                ),
                dropdownColor: AppTheme.surfaceLight,
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ...BearingDatabase.commonBearings.map((b) {
                    return DropdownMenuItem(value: b.name, child: Text(b.name));
                  }),
                ],
                onChanged: (value) => setState(() => bearingType = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  final point = MeasurementPoint(
                    id: const Uuid().v4(),
                    locationId: location.id,
                    name: nameController.text,
                    direction: direction,
                    bearingType: bearingType,
                  );
                  provider.addPoint(point);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePoint(BuildContext context, MeasurementPoint point) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.primaryMid,
        title: const Text('Delete Point'),
        content: Text(
          'Delete "${point.name}"?\nAll measurement history will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deletePoint(point.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusUnacceptable,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
