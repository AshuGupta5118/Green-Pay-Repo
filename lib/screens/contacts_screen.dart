import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:green_pay/models/contact.dart';
import 'package:green_pay/services/contact_service.dart';
import 'package:green_pay/widgets/custom_text_field.dart';
import 'package:green_pay/services/api_service.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _contactService =
      ContactService(ApiService(baseUrl: APIEndpoints.baseUrl));
  final _searchController = TextEditingController();
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  bool _isLoading = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);

    try {
      final contacts = await _contactService.getContacts();
      setState(() {
        _contacts = contacts;
        _filteredContacts = contacts;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _syncContacts() async {
    setState(() => _isSyncing = true);

    try {
      final contacts = await _contactService.syncDeviceContacts();
      setState(() {
        _contacts = contacts;
        _filteredContacts = contacts;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contacts synced successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  void _filterContacts(String query) {
    setState(() {
      _filteredContacts = _contacts.where((contact) {
        final name = contact.name.toLowerCase();
        final phone = contact.phoneNumber?.toLowerCase() ?? '';
        final email = contact.email?.toLowerCase() ?? '';
        final search = query.toLowerCase();
        return name.contains(search) ||
            phone.contains(search) ||
            email.contains(search);
      }).toList();
    });
  }

  Future<void> _toggleFavorite(Contact contact) async {
    try {
      await _contactService.toggleFavorite(contact.id);
      await _loadContacts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _showContactDetails(Contact contact) async {
    try {
      final analytics = await _contactService.getContactAnalytics(contact.id);
      if (!mounted) return;

      showCupertinoModalPopup(
        context: context,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.only(top: 12),
          decoration: const BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey4,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      contact.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Icon(
                        contact.isFavorite
                            ? CupertinoIcons.heart_fill
                            : CupertinoIcons.heart,
                        color: contact.isFavorite
                            ? CupertinoColors.systemRed
                            : null,
                      ),
                      onPressed: () => _toggleFavorite(contact),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (contact.phoneNumber != null) ...[
                      _buildContactInfoItem(
                          CupertinoIcons.phone, 'Phone', contact.phoneNumber!),
                      const SizedBox(height: 16),
                    ],
                    if (contact.email != null) ...[
                      _buildContactInfoItem(
                          CupertinoIcons.mail, 'Email', contact.email!),
                      const SizedBox(height: 16),
                    ],
                    if (contact.upiId != null) ...[
                      _buildContactInfoItem(CupertinoIcons.money_dollar_circle,
                          'UPI ID', contact.upiId!),
                      const SizedBox(height: 16),
                    ],
                    const Text(
                      'Transaction History',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // TODO: Show transaction history using analytics data
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(CupertinoIcons.money_dollar, 'Pay',
                        CupertinoColors.activeGreen, () {
                      // TODO: Implement payment
                      Navigator.pop(context);
                    }),
                    _buildActionButton(CupertinoIcons.chat_bubble, 'Message',
                        CupertinoColors.activeBlue, () {
                      // TODO: Implement messaging
                      Navigator.pop(context);
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Widget _buildContactInfoItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: CupertinoColors.systemGrey,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
      IconData icon, String label, Color color, VoidCallback onPressed) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Contacts'),
        trailing: _isSyncing
            ? const CupertinoActivityIndicator()
            : CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.arrow_2_circlepath),
                onPressed: _syncContacts,
              ),
      ),
      child: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: CustomTextField(
                    controller: _searchController,
                    placeholder: 'Search contacts...',
                    prefix: const Icon(CupertinoIcons.search),
                    onChanged: _filterContacts,
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CupertinoActivityIndicator())
                      : _filteredContacts.isEmpty
                          ? const Center(
                              child: Text('No contacts found'),
                            )
                          : ListView.builder(
                              itemCount: _filteredContacts.length,
                              itemBuilder: (context, index) {
                                final contact = _filteredContacts[index];
                                return Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: CupertinoColors.systemGrey5,
                                        width: 0.5,
                                      ),
                                    ),
                                  ),
                                  child: CupertinoListTile(
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: CupertinoColors.activeBlue
                                            .withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          contact.name[0].toUpperCase(),
                                          style: const TextStyle(
                                            color: CupertinoColors.activeBlue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    title: Text(contact.name),
                                    subtitle: Text(
                                      contact.phoneNumber ??
                                          contact.email ??
                                          '',
                                      style: const TextStyle(
                                        color: CupertinoColors.systemGrey,
                                        fontSize: 14,
                                      ),
                                    ),
                                    trailing: CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      child: Icon(
                                        contact.isFavorite
                                            ? CupertinoIcons.heart_fill
                                            : CupertinoIcons.heart,
                                        color: contact.isFavorite
                                            ? CupertinoColors.systemRed
                                            : null,
                                        size: 22,
                                      ),
                                      onPressed: () => _toggleFavorite(contact),
                                    ),
                                    onTap: () => _showContactDetails(contact),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: GestureDetector(
              onTap: () {
                // TODO: Implement add contact
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: CupertinoColors.activeBlue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.systemGrey.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.add,
                  color: CupertinoColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
