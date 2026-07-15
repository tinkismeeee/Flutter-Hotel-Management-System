import 'package:flutter/material.dart';

import '../../../models/customer.dart';
import '../../../services/customer_service.dart';

class MyProfileScreen extends StatefulWidget {
  final String userId;

  const MyProfileScreen({super.key, required this.userId});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  late Future<Customer> _customer;
  Customer? _lastCustomer;

  @override
  void initState() {
    super.initState();
    _customer = _loadCustomer();
  }

  Future<Customer> _loadCustomer() async {
    final customer = await CustomerService.getCustomerById(widget.userId);
    _lastCustomer = customer;
    return customer;
  }

  void _retry() {
    setState(() {
      _customer = _loadCustomer();
    });
  }

  Future<void> _refresh() async {
    final customer = _loadCustomer();
    setState(() {
      _customer = customer;
    });
    try {
      await customer;
    } catch (_) {
      // The FutureBuilder presents the retryable error state.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: FutureBuilder<Customer>(
        future: _customer,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done &&
              _lastCustomer == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.connectionState == ConnectionState.done &&
              (snapshot.hasError || !snapshot.hasData)) {
            return _ProfileError(onRetry: _retry);
          }

          final customer = snapshot.data ?? _lastCustomer!;
          final fullName =
              '${customer.firstName.trim()} ${customer.lastName.trim()}'.trim();

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                _ProfileField(
                  icon: Icons.person_outline,
                  label: 'Username',
                  value: _valueOrPlaceholder(customer.username),
                ),
                _ProfileField(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: _valueOrPlaceholder(customer.email),
                ),
                _ProfileField(
                  icon: Icons.badge_outlined,
                  label: 'Full name',
                  value: _valueOrPlaceholder(fullName),
                ),
                _ProfileField(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: _valueOrPlaceholder(customer.phoneNumber),
                ),
                _ProfileField(
                  icon: Icons.location_on_outlined,
                  label: 'Address',
                  value: _valueOrPlaceholder(customer.address),
                ),
                _ProfileField(
                  icon: Icons.cake_outlined,
                  label: 'Date of birth',
                  value: _valueOrPlaceholder(customer.dateOfBirth),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _valueOrPlaceholder(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? 'Not updated' : trimmed;
  }
}

class _ProfileField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileField({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}

class _ProfileError extends StatelessWidget {
  final VoidCallback onRetry;

  const _ProfileError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.error_outline, size: 48),
        const SizedBox(height: 16),
        Text(
          'Unable to load profile',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Check your connection and try again.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        Center(
          child: FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}
