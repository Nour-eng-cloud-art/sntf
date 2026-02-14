import 'package:flutter/material.dart';


class LegalTextPage extends StatelessWidget {
  final String title;
  const LegalTextPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(title: Text(title), backgroundColor: Colors.transparent),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(
          "Article 1: Objet\nLes présentes conditions régissent l'utilisation des services SNTF...\n\n" * 10,
          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
        ),
      ),
    );
  }
}