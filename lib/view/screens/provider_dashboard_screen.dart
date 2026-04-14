import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/request_view_model.dart';
import '../../view_models/auth_view_model.dart';
import '../../models/service_request_model.dart';
import 'package:intl/intl.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final providerId = context.read<AuthViewModel>().currentUser?.uid;
      if (providerId != null) {
        context.read<RequestViewModel>().listenToIncomingRequests(providerId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthViewModel>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthViewModel>().logout();
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Header summary
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Icon(Icons.engineering, size: 30, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, ${user?.name ?? 'Provider'}',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Online & Active',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
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

          // Requests List
          Expanded(
            child: Consumer<RequestViewModel>(
              builder: (context, requestVM, child) {
                if (requestVM.incomingRequests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'No incoming requests right now.',
                          style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: requestVM.incomingRequests.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final request = requestVM.incomingRequests[index];
                    return _buildRequestCard(context, request, requestVM);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, ServiceRequestModel request, RequestViewModel requestVM) {
    final theme = Theme.of(context);
    final isPending = request.status == RequestStatus.pending;
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'New ${request.serviceType} Request',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPending ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  request.status.name.toUpperCase(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isPending ? Colors.orange : Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                DateFormat('MMM dd, yyyy - hh:mm a').format(request.timestamp),
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (isPending)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => requestVM.declineRequest(request.requestId),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => requestVM.acceptRequest(request.requestId),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
