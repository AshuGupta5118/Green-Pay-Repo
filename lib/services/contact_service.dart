import 'package:contacts_service/contacts_service.dart' as device_contacts;
import 'package:permission_handler/permission_handler.dart';
import 'package:green_pay/models/contact.dart';
import 'package:green_pay/services/api_service.dart';

class ContactService {
  final ApiService _apiService;

  ContactService(this._apiService);

  Future<bool> requestContactPermission() async {
    final status = await Permission.contacts.request();
    return status.isGranted;
  }

  Future<List<Contact>> getContacts() async {
    final response = await _apiService.get('/contacts');
    return (response['data'] as List)
        .map((json) => Contact.fromJson(json))
        .toList();
  }

  Future<List<Contact>> getFavoriteContacts() async {
    final response = await _apiService.get('/contacts/favorites');
    return (response['data'] as List)
        .map((json) => Contact.fromJson(json))
        .toList();
  }

  Future<Contact> addContact(Contact contact) async {
    final response = await _apiService.post('/contacts', contact.toJson());
    return Contact.fromJson(response['data']);
  }

  Future<Contact> updateContact(Contact contact) async {
    final response = await _apiService.put(
      '/contacts/${contact.id}',
      contact.toJson(),
    );
    return Contact.fromJson(response['data']);
  }

  Future<void> deleteContact(String contactId) async {
    await _apiService.delete('/contacts/$contactId');
  }

  Future<void> toggleFavorite(String contactId) async {
    await _apiService.post('/contacts/$contactId/toggle-favorite', {});
  }

  Future<List<Contact>> syncDeviceContacts() async {
    if (!await requestContactPermission()) {
      throw Exception('Contact permission denied');
    }

    final deviceContactsList =
        await device_contacts.ContactsService.getContacts();
    final contactsToSync = deviceContactsList.map((contact) {
      return {
        'name': contact.displayName ?? '',
        'phoneNumber': contact.phones?.firstOrNull?.value,
        'email': contact.emails?.firstOrNull?.value,
      };
    }).toList();

    final response = await _apiService.post('/contacts/sync', {
      'contacts': contactsToSync,
    });

    return (response['data'] as List)
        .map((json) => Contact.fromJson(json))
        .toList();
  }

  Future<List<Contact>> searchContacts(String query) async {
    final response = await _apiService.get(
      '/contacts/search',
      queryParameters: {'q': query},
    );
    return (response['data'] as List)
        .map((json) => Contact.fromJson(json))
        .toList();
  }

  Future<Map<String, dynamic>> getContactAnalytics(String contactId) async {
    final response = await _apiService.get('/contacts/$contactId/analytics');
    return response['data'];
  }
}
