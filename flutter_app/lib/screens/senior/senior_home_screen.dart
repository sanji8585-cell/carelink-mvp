import 'package:flutter/material.dart';

class SeniorHomeScreen extends StatefulWidget {
  const SeniorHomeScreen({super.key});

  @override
  State<SeniorHomeScreen> createState() => _SeniorHomeScreenState();
}

class _SeniorHomeScreenState extends State<SeniorHomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  int _todaySteps = 4230;
  String _mood = '좋음';
  bool _morningMedTaken = false;
  bool _noonMedTaken = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _startConversation() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const _ConversationScreen()));
  }

  void _triggerSos() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('🚨 긴급 SOS', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('가족과 119에 긴급 연락을 보냅니다.\n정말 보내시겠어요?', style: TextStyle(fontSize: 18, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(fontSize: 18)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ 긴급 연락을 보냈습니다'), backgroundColor: Color(0xFFE85D3A)),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('보내기', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F2),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 헤더
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF1B6B4A), Color(0xFF2D8B62)]),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('케어링크', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    const Text('안녕하세요, 어머님 👋', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('오늘도 건강한 하루 보내세요!', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 15)),
                  ],
                ),
              ),

              // AI 대화 버튼 (오버랩)
              Transform.translate(
                offset: const Offset(0, -28),
                child: GestureDetector(
                  onTap: _startConversation,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, child) {
                      final scale = 1.0 + (_pulseController.value * 0.05);
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Container(
                      width: 140, height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: [Color(0xFFE85D3A), Color(0xFFF08C5A)]),
                        border: Border.all(color: Colors.white, width: 6),
                        boxShadow: [BoxShadow(color: const Color(0xFFE85D3A).withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 8))],
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('🎙️', style: TextStyle(fontSize: 36)),
                          SizedBox(height: 4),
                          Text('대화하기', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // 약 복용 카드
                    _buildMedCard(),
                    const SizedBox(height: 12),

                    // 걸음수 + 기분 카드
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('🚶', '$_todaySteps', '오늘 걸음수', const Color(0xFF1B6B4A))),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard('😊', _mood, '오늘 기분', const Color(0xFF2563EB))),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // SOS 버튼
                    GestureDetector(
                      onTap: _triggerSos,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFEF4444)]),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: const Color(0xFFDC2626).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))],
                        ),
                        child: const Center(
                          child: Text('🚨 긴급 SOS', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 1)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 영상통화 버튼
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Column(
                          children: [
                            Text('📹', style: TextStyle(fontSize: 28)),
                            SizedBox(height: 4),
                            Text('자녀와 영상통화', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFF0EC), Colors.white]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💊 약 복용 알림', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _buildMedRow('혈압약 · 당뇨약 (아침 8시)', _morningMedTaken, () {
            setState(() => _morningMedTaken = true);
          }),
          const SizedBox(height: 8),
          _buildMedRow('비타민D (점심 12시)', _noonMedTaken, () {
            setState(() => _noonMedTaken = true);
          }),
        ],
      ),
    );
  }

  Widget _buildMedRow(String name, bool taken, VoidCallback onTap) {
    return Row(
      children: [
        Expanded(
          child: Text(name, style: TextStyle(
            fontSize: 17, fontWeight: FontWeight.w700,
            color: taken ? Colors.grey : const Color(0xFFE85D3A),
            decoration: taken ? TextDecoration.lineThrough : null,
          )),
        ),
        GestureDetector(
          onTap: taken ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: taken ? const Color(0xFF16A34A) : const Color(0xFFE85D3A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              taken ? '완료 ✓' : '먹었어요',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String emoji, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ===== AI 대화 화면 =====
class _ConversationScreen extends StatefulWidget {
  const _ConversationScreen();

  @override
  State<_ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<_ConversationScreen> {
  final List<_ChatMessage> _messages = [];
  bool _isListening = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startConversation();
  }

  void _startConversation() {
    setState(() {
      _messages.add(_ChatMessage(role: 'ai', text: '안녕하세요 어머님! 오늘 하루 어떠셨어요? 😊'));
    });

    // 데모용 자동 대화 시뮬레이션
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _messages.add(_ChatMessage(role: 'user', text: '오늘은 좀 괜찮았어. 산책도 다녀왔어.')));
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _messages.add(_ChatMessage(role: 'ai', text: '산책 다녀오셨군요! 정말 잘 하셨어요. 오늘 약은 드셨나요?')));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8F5EE),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B6B4A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('AI 말벗', style: TextStyle(color: Color(0xFF1B6B4A), fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final msg = _messages[i];
                final isUser = msg.role == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF1B6B4A) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isUser ? 20 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 20),
                      ),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
                    ),
                    child: Text(msg.text, style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 17, fontWeight: FontWeight.w500, height: 1.5,
                    )),
                  ),
                );
              },
            ),
          ),

          // 마이크 버튼
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _isListening = !_isListening),
                  child: Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening ? const Color(0xFFE85D3A) : const Color(0xFF1B6B4A),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 16, offset: const Offset(0, 4))],
                    ),
                    child: Icon(_isListening ? Icons.pause : Icons.mic, color: Colors.white, size: 32),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isListening ? '듣고 있어요...' : '버튼을 눌러 말씀하세요',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String role;
  final String text;
  _ChatMessage({required this.role, required this.text});
}
