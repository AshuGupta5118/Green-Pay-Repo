import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/payment_card.dart';

class CardService {
  static const _storage = FlutterSecureStorage();

  static const _cardsKey = 'payment_cards';
  static const _uuid = Uuid();

  Future<List<PaymentCard>> getCards() async {
    try {
      final cardsJson = await _storage.read(key: _cardsKey);
      if (cardsJson == null) return [];

      final List<dynamic> cardsList = jsonDecode(cardsJson);
      return cardsList
          .map((card) => PaymentCard.fromJson(card as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addCard(PaymentCard card) async {
    try {
      final cards = await getCards();
      cards.add(card);
      await _saveCards(cards);
    } catch (e) {
      throw Exception('Failed to add card');
    }
  }

  Future<void> removeCard(String cardId) async {
    try {
      final cards = await getCards();
      cards.removeWhere((card) => card.id == cardId);
      await _saveCards(cards);
    } catch (e) {
      throw Exception('Failed to remove card');
    }
  }

  Future<void> _saveCards(List<PaymentCard> cards) async {
    try {
      final cardsJson = jsonEncode(cards.map((card) => card.toJson()).toList());
      await _storage.write(key: _cardsKey, value: cardsJson);
    } catch (e) {
      throw Exception('Failed to save cards');
    }
  }

  String generateCardId() {
    return _uuid.v4();
  }

  Future<void> clearCards() async {
    try {
      await _storage.delete(key: _cardsKey);
    } catch (e) {
      throw Exception('Failed to clear cards');
    }
  }
}
