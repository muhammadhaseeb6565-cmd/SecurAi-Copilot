import 'package:flutter/material.dart';

class NetworkMapScreen extends StatefulWidget {
  const NetworkMapScreen({super.key});

  @override
  State<NetworkMapScreen> createState() => _NetworkMapScreenState();
}

class _NetworkMapScreenState extends State<NetworkMapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Widget _buildNode(
    String name,
    IconData icon,
    Color color, {
    bool isUnderAttack = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isUnderAttack)
          FadeTransition(
            opacity: _pulseController,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "ATTACK DETECTED",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
        else
          const SizedBox(height: 20),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: isUnderAttack ? Colors.red : color,
              width: isUnderAttack ? 3 : 1,
            ),
            boxShadow: isUnderAttack
                ? [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ]
                : [],
          ),
          child: Icon(icon, size: 36, color: color),
        ),
        const SizedBox(height: 8),
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildLine() {
    return Container(
      width: 40,
      height: 2,
      color: Colors.grey.withValues(alpha: 0.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Interactive Architecture Map",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildNode("Load Balancer", Icons.cloud, Colors.blue),
                _buildLine(),
                _buildNode("API Gateway", Icons.router, Colors.purple),
                _buildLine(),
                _buildNode(
                  "Auth Service",
                  Icons.security,
                  Colors.orange,
                  isUnderAttack: true,
                ), // Simulate attack
                _buildLine(),
                _buildNode("User DB", Icons.storage, Colors.green),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
