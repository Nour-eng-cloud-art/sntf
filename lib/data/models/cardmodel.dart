import 'package:flutter/material.dart';

class CardModel {
  final String title;
  final String subtitle;
  final String price;
  final String expiryDate;
  final LinearGradient gradient;
  final String clientId;
  final String clientName;
  final String cardType;

  CardModel({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.expiryDate,
    required this.gradient,
    required this.clientId,
    required this.clientName,
    required this.cardType,
  });
}