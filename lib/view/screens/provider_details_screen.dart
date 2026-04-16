import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../models/user_model.dart';
import '../../models/notification_model.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/request_view_model.dart';
import '../../services/firebase_service.dart';
import 'package:intl/intl.dart';

class ProviderDetailsScreen extends StatefulWidget {
  final UserModel provider;

  const ProviderDetailsScreen({super.key, required this.provider});

  @override
  State<ProviderDetailsScreen> createState() => _ProviderDetailsScreenState();
}

class _ProviderDetailsScreenState extends State<ProviderDetailsScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _descriptionController = TextEditingController();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _showRequestDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Schedule Service'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text(_selectedDate == null 
                        ? 'Select Date' 
                        : DateFormat('EEE, MMM dd, yyyy').format(_selectedDate!)),
                    leading: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        setDialogState(() => _selectedDate = picked);
                        setState(() {});
                      }
                    },
                  ),
                  ListTile(
                    title: Text(_selectedTime == null 
                        ? 'Select Time' 
                        : _selectedTime!.format(context)),
                    leading: const Icon(Icons.access_time),
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) {
                        setDialogState(() => _selectedTime = picked);
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Task Description',
                      hintText: 'Describe what needs to be done...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: (_selectedDate == null || _selectedTime == null) 
                    ? null 
                    : () => _submitRequest(),
                child: const Text('Send Request'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _submitRequest() async {
    final consumer = context.read<AuthViewModel>().currentUser;
    if (consumer == null) return;

    final scheduledDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    try {
      await context.read<RequestViewModel>().sendRequest(
        consumerId: consumer.uid,
        providerId: widget.provider.uid,
        serviceType: widget.provider.serviceType ?? 'General',
        location: consumer.location ?? widget.provider.location ?? const GeoPoint(0, 0),
        scheduledDate: scheduledDateTime,
        description: _descriptionController.text,
      );

      // Send notification
      final notif = NotificationModel(
        notificationId: const Uuid().v4(),
        recipientId: widget.provider.uid,
        title: 'New Service Request',
        body: '${consumer.name} requested ${widget.provider.serviceType} for ${DateFormat('MMM dd, hh:mm a').format(scheduledDateTime)}',
        timestamp: DateTime.now(),
      );
      FirebaseService().saveNotification(notif);

      if (mounted) {
        Navigator.pop(context); // Close dialog
        Navigator.pop(context); // Go back to home
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service request sent successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Provider Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Icon(Icons.person, size: 60, color: Theme.of(context).primaryColor),
                  ),
                  const SizedBox(height: 16),
                  Text(widget.provider.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  Text(widget.provider.serviceType ?? 'General Service', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildInfoSection('About', widget.provider.bio ?? 'No bio available.'),
            const SizedBox(height: 20),
            _buildInfoSection('Hourly Rate', '\$${widget.provider.hourlyRate ?? 0} / hour'),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 8),
                Text('${widget.provider.rating} (${widget.provider.reviewCount} reviews)', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _showRequestDialog,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('Request Service', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(content, style: const TextStyle(fontSize: 15, color: Colors.black87)),
      ],
    );
  }
}
