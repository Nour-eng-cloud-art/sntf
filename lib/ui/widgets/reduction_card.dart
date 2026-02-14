import 'dart:math';
import 'package:flutter/material.dart';
// Note: Assure-toi que les imports correspondent à ton projet
import 'package:sntf/core/theme/app_colors.dart';
import 'package:sntf/core/theme/app_text_styles.dart';

class ReductionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String price;
  final String expiryDate;
  final Gradient gradient;
  final String clientName;
  final String clientId;
  final String cardType;

  const ReductionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.expiryDate,
    required this.gradient,
    required this.clientName,
    required this.clientId,
    required this.cardType,
  });

  @override
  State<ReductionCard> createState() => _ReductionCardState();
}

class _ReductionCardState extends State<ReductionCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleCard() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() {
      _isFront = !_isFront;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleCard,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final angle = _controller.value * pi;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001) 
            ..rotateY(angle);

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            // On utilise LayoutBuilder pour obtenir la largeur parente et la fixer au contenu
            child: angle < pi / 2
                ? _buildFront() 
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: _buildBack(), 
                  ),
          );
        },
      ),
    );
  }

  Widget _buildFront() {
    return _cardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _labelBadge("SNTF PASS"),
              const Icon(Icons.contactless, color: Colors.white70, size: 28),
            ],
          ),
          const Spacer(),
          Text(
            widget.title, 
            style: AppTextStyles.headlineSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            maxLines: 1, // Évite les sauts de ligne imprévus
          ),
          Text(
            widget.subtitle, 
            style: TextStyle(color: Colors.white.withOpacity(0.8)),
            maxLines: 1,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoColumn("VALABLE JUSQU'AU", widget.expiryDate),
              _priceBadge(widget.price),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBack() {
    return _cardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _labelBadge("INFOS CLIENT"),
              const Icon(Icons.qr_code_2, color: Colors.white70, size: 32),
            ],
          ),
          const Spacer(),
          _infoField("TITULAIRE", widget.clientName),
          const SizedBox(height: 12),
          _infoField("ID CLIENT", widget.clientId),
          const SizedBox(height: 12),
          _infoField("TYPE DE CARTE", widget.cardType.toUpperCase()),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              "SNTF MOBILE SERVICES",
              style: TextStyle(color: Colors.white.withAlpha(50), fontSize: 10, letterSpacing: 1),
            ),
          )
        ],
      ),
    );
  }

  Widget _cardContainer({required Widget child}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          height: 240, 

          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: widget.gradient,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Positioned(
                  top: -50, 
                  right: -50, 
                  child: CircleAvatar(radius: 100, backgroundColor: Colors.white.withOpacity(0.1))
                ),
                
                SizedBox(
                  width: constraints.maxWidth,
                  height: 240,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0), 
                    child: child
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  // Les autres petits widgets (badges, colonnes) restent identiques
  Widget _labelBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
    );
  }

  Widget _infoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 9, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _infoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _priceBadge(String price) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
      child: Text(price, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 14)),
    );
  }
}