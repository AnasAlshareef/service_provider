import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reservation_provider.dart';
import '../../models/reservation_model.dart';

class ProviderReservationsScreen extends StatefulWidget {
  const ProviderReservationsScreen({super.key});

  @override
  State<ProviderReservationsScreen> createState() => _ProviderReservationsScreenState();
}

class _ProviderReservationsScreenState extends State<ProviderReservationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReservations();
    });
  }

  void _loadReservations() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final reservationProvider = Provider.of<ReservationProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      reservationProvider.loadProviderReservations(authProvider.user!.uid);
    }
  }

  Future<void> _respondToReservation(ReservationModel reservation, bool accept) async {
    final TextEditingController responseController = TextEditingController();
    
    String? response = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(accept ? 'Accept Reservation' : 'Decline Reservation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Service: ${reservation.serviceTitle}'),
            Text('Customer: ${reservation.customerName}'),
            Text('Date: ${reservation.requestedDate.day}/${reservation.requestedDate.month}/${reservation.requestedDate.year}'),
            Text('Time: ${reservation.requestedTime}'),
            const SizedBox(height: 16),
            TextField(
              controller: responseController,
              decoration: InputDecoration(
                labelText: accept ? 'Acceptance Message (Optional)' : 'Decline Reason (Optional)',
                hintText: accept 
                    ? 'Thank you for choosing our service...'
                    : 'Unfortunately, we cannot accommodate...',
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, responseController.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: accept ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(accept ? 'Accept' : 'Decline'),
          ),
        ],
      ),
    );

    if (response != null) {
      final reservationProvider = Provider.of<ReservationProvider>(context, listen: false);
      bool success;
      
      if (accept) {
        success = await reservationProvider.acceptReservation(
          reservation.id, 
          response.isEmpty ? null : response,
        );
      } else {
        success = await reservationProvider.declineReservation(
          reservation.id, 
          response.isEmpty ? null : response,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
                ? 'Reservation ${accept ? 'accepted' : 'declined'} successfully!' 
                : reservationProvider.errorMessage ?? 'Failed to respond to reservation'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _completeReservation(String reservationId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Reservation'),
        content: const Text('Mark this reservation as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final reservationProvider = Provider.of<ReservationProvider>(context, listen: false);
      bool success = await reservationProvider.completeReservation(reservationId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
                ? 'Reservation completed successfully!' 
                : reservationProvider.errorMessage ?? 'Failed to complete reservation'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReservationProvider>(
      builder: (context, reservationProvider, child) {
        if (reservationProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (reservationProvider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  reservationProvider.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadReservations,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        List<ReservationModel> reservations = reservationProvider.providerReservations;

        if (reservations.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.book_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No reservations yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Reservations will appear here when customers book your services',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Group reservations by status
        List<ReservationModel> pendingReservations = reservations
            .where((r) => r.status == ReservationStatus.confirmed)
            .toList();
        List<ReservationModel> otherReservations = reservations
            .where((r) => r.status != ReservationStatus.confirmed)
            .toList();

        return RefreshIndicator(
          onRefresh: () async => _loadReservations(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pendingReservations.isNotEmpty) ...[
                  const Text(
                    'Pending Responses',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...pendingReservations.map((reservation) => 
                      _buildReservationCard(reservation, isPending: true)),
                  const SizedBox(height: 24),
                ],
                
                if (otherReservations.isNotEmpty) ...[
                  const Text(
                    'All Reservations',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...otherReservations.map((reservation) => 
                      _buildReservationCard(reservation, isPending: false)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReservationCard(ReservationModel reservation, {required bool isPending}) {
    Color statusColor = _getStatusColor(reservation.status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isPending ? 4 : 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    reservation.serviceTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    reservation.statusDisplayName,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Customer: ${reservation.customerName}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${reservation.requestedDate.day}/${reservation.requestedDate.month}/${reservation.requestedDate.year}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  reservation.requestedTime,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Price: \$${reservation.servicePrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            if (reservation.notes != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Customer Notes:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reservation.notes!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
            if (reservation.providerResponse != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Response:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reservation.providerResponse!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (reservation.canBeRespondedByProvider) ...[
                  ElevatedButton(
                    onPressed: () => _respondToReservation(reservation, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Accept'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _respondToReservation(reservation, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Decline'),
                  ),
                ] else if (reservation.status == ReservationStatus.accepted) ...[
                  ElevatedButton(
                    onPressed: () => _completeReservation(reservation.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Mark Complete'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return Colors.orange;
      case ReservationStatus.confirmed:
        return Colors.blue;
      case ReservationStatus.accepted:
        return Colors.green;
      case ReservationStatus.declined:
        return Colors.red;
      case ReservationStatus.cancelled:
        return Colors.grey;
      case ReservationStatus.completed:
        return Colors.purple;
    }
  }
}

