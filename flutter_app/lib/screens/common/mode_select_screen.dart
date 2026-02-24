import 'package:flutter/material.dart';

class ModeSelectScreen extends StatelessWidget {
  const ModeSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F2),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              // Logo
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B6B4A),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.favorite, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 16),
              Text('케어링크', style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: const Color(0xFF1B6B4A),
              )),
              const SizedBox(height: 8),
              Text('스마트폰 하나로, 부모님 곁에 늘 함께합니다',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const Spacer(),

              // 부모님 앱 버튼
              _ModeButton(
                icon: Icons.elderly,
                title: '부모님 앱',
                subtitle: 'AI 말벗 · 건강 체크 · 긴급 SOS',
                color: const Color(0xFFE85D3A),
                onTap: () => Navigator.pushReplacementNamed(context, '/senior'),
              ),
              const SizedBox(height: 16),

              // 자녀 앱 버튼
              _ModeButton(
                icon: Icons.family_restroom,
                title: '자녀(보호자) 앱',
                subtitle: '건강 대시보드 · 주간 리포트 · 알림',
                color: const Color(0xFF2563EB),
                onTap: () => Navigator.pushReplacementNamed(context, '/login'),
              ),
              const Spacer(flex: 1),

              Text('v0.1.0 MVP', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon, required this.title, required this.subtitle,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: color.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8))],
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color.withOpacity(0.5), size: 20),
          ],
        ),
      ),
    );
  }
}
