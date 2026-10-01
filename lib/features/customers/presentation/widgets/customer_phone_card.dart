import 'package:flutter/material.dart';
import 'customer_phone_edit_form.dart';
import 'pending_sync_badge.dart';

/// Card enabling viewing and updating of customer phone number.
class CustomerPhoneCard extends StatefulWidget {
  final String? initialPhone;
  final bool isUpdating;
  final bool isPendingSync;
  final ValueChanged<String> onSave;

  const CustomerPhoneCard({
    super.key,
    required this.initialPhone,
    required this.isUpdating,
    this.isPendingSync = false,
    required this.onSave,
  });

  @override
  State<CustomerPhoneCard> createState() => _CustomerPhoneCardState();
}

class _CustomerPhoneCardState extends State<CustomerPhoneCard> {
  late final TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialPhone ?? '');
  }

  @override
  void didUpdateWidget(covariant CustomerPhoneCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPhone != oldWidget.initialPhone && !_isEditing) {
      _controller.text = widget.initialPhone ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSave() {
    final newPhone = _controller.text.trim();
    widget.onSave(newPhone);
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme),
              const SizedBox(height: 8),
              if (_isEditing || widget.isUpdating)
                CustomerPhoneEditForm(
                  controller: _controller,
                  isUpdating: widget.isUpdating,
                  onCancel: () {
                    _controller.text = widget.initialPhone ?? '';
                    setState(() => _isEditing = false);
                  },
                  onSave: _handleSave,
                )
              else
                _buildDisplayView(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.phone_outlined, color: theme.colorScheme.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              'Phone Number',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (widget.isPendingSync) ...[
              const SizedBox(width: 8),
              const PendingSyncBadge(),
            ],
          ],
        ),
        if (!_isEditing && !widget.isUpdating)
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: 'Edit Phone',
            onPressed: () => setState(() => _isEditing = true),
          ),
      ],
    );
  }

  Widget _buildDisplayView(ThemeData theme) {
    return Text(
      widget.initialPhone?.isNotEmpty == true
          ? widget.initialPhone!
          : 'No phone number provided',
      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
    );
  }
}
