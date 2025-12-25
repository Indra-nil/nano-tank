import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;     // ✅ ADDED margin support
  final EdgeInsetsGeometry? padding;    // ✅ BONUS: padding support
  final double? borderRadius;           // ✅ BONUS: customizable radius
  
  const GlassCard({
    Key? key, 
    required this.child,
    this.margin,
    this.padding,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,                           // ✅ SUPPORTS margin
      padding: padding ?? EdgeInsets.all(20),   // ✅ SUPPORTS padding
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(borderRadius ?? 20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}