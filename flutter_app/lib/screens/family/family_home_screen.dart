import 'package:flutter/material.dart';

class FamilyHomeScreen extends StatefulWidget {
  const FamilyHomeScreen({super.key});

  @override
  State<FamilyHomeScreen> createState() => _FamilyHomeScreenState();
}

class _FamilyHomeScreenState extends State<FamilyHomeScreen> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF334155)]),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text('케어링크 · 보호자', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      IconButton(
                        icon: Badge(
                          label: const Text('2'),
                          child: Icon(Icons.notifications_outlined, color: Colors.white.withOpacity(0.7)),
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(colors: [Color(0xFF16A34A), Color(0xFF22C55E)]),
                          boxShadow: [BoxShadow(color: const Color(0xFF22C55E).withOpacity(0.3), blurRadius: 8)],
                        ),
                        child: const Center(child: Text('👵', style: TextStyle(fontSize: 26))),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('김순자 어머님', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(width: 8, height: 8, decoration: BoxDecoration(
                                shape: BoxShape.circle, color: const Color(0xFF22C55E),
                                boxShadow: [BoxShadow(color: const Color(0xFF22C55E).withOpacity(0.5), blurRadius: 6)],
                              )),
                              const SizedBox(width: 6),
                              const Text('정상 · 최근 대화 2시간 전', style: TextStyle(color: Color(0xFF22C55E), fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 탭
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  _buildTab(0, '📊', '대시보드'),
                  const SizedBox(width: 4),
                  _buildTab(1, '📋', '주간리포트'),
                  const SizedBox(width: 4),
                  _buildTab(2, '🏥', '돌봄관리'),
                ],
              ),
            ),

            // 콘텐츠
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: _currentTab == 0 ? _buildDashboard()
                     : _currentTab == 1 ? _buildReport()
                     : _buildCareManagement(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int index, String icon, String label) {
    final selected = _currentTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: selected ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)] : null,
          ),
          child: Center(
            child: Text('$icon $label', style: TextStyle(
              fontSize: 13, fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.black87 : Colors.grey[500],
            )),
          ),
        ),
      ),
    );
  }

  // ===== 대시보드 탭 =====
  Widget _buildDashboard() {
    return Column(
      children: [
        // 경고 카드
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)]),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('수요일 활동량 감소 감지', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF92400E))),
                    const SizedBox(height: 2),
                    Text('평소 대비 35% 감소. 컨디션 확인 권장', style: TextStyle(fontSize: 12, color: Colors.brown[600])),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 통계 그리드
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.4,
          children: [
            _statCard('🚶', '4,230', '오늘 걸음', '▲ 12% vs 어제', const Color(0xFF16A34A)),
            _statCard('😴', '7.3h', '어젯밤 수면', '양호', const Color(0xFF2563EB)),
            _statCard('💊', '1/2', '복약 현황', '비타민 미복용', const Color(0xFFF59E0B)),
            _statCard('🧠', '92', '인지 점수', '정상 범위', const Color(0xFF7C3AED)),
          ],
        ),
        const SizedBox(height: 12),

        // 주간 걸음수 차트
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('📈 주간 걸음수', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              SizedBox(
                height: 100,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var d in [
                      {'day': '월', 'steps': 3200}, {'day': '화', 'steps': 4500},
                      {'day': '수', 'steps': 2800}, {'day': '목', 'steps': 5100},
                      {'day': '금', 'steps': 3800}, {'day': '토', 'steps': 4230},
                      {'day': '일', 'steps': 0},
                    ]) Expanded(child: _barItem(d['day'] as String, d['steps'] as int, 5100)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // AI 대화 요약
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFEFF6FF), Colors.white]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🤖 오늘 AI 대화 요약', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
              const SizedBox(height: 8),
              RichText(text: const TextSpan(
                style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.6, fontFamily: 'Pretendard'),
                children: [
                  TextSpan(text: '오늘 오후 2시 대화에서 어머님은 '),
                  TextSpan(text: '산책을 다녀오셨다', style: TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: '고 하셨습니다. 기분은 '),
                  TextSpan(text: '좋은 편', style: TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: '이며, 혈압약 복용을 잊으셔서 AI가 안내 드렸습니다.'),
                ],
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statCard(String emoji, String value, String label, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$emoji $label', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color)),
          Text(sub, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _barItem(String day, int steps, int maxSteps) {
    final height = steps > 0 ? (steps / maxSteps * 70).clamp(8.0, 70.0) : 4.0;
    final isLow = steps > 0 && steps < 3000;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (steps > 0) Text('${(steps / 1000).toStringAsFixed(1)}k', style: TextStyle(fontSize: 9, color: Colors.grey[500])),
          const SizedBox(height: 4),
          Container(
            width: double.infinity, height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter, end: Alignment.topCenter,
                colors: isLow ? [const Color(0xFFEF4444), const Color(0xFFFCA5A5)] : [const Color(0xFF16A34A), const Color(0xFF86EFAC)],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(day, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        ],
      ),
    );
  }

  // ===== 주간 리포트 탭 =====
  Widget _buildReport() {
    final items = [
      {'icon': '🚶', 'title': '활동량', 'status': '양호', 'color': const Color(0xFF16A34A), 'detail': '평균 3,943보/일. 수요일 활동량 감소(2,800보) 외 안정적'},
      {'icon': '😴', 'title': '수면', 'status': '양호', 'color': const Color(0xFF16A34A), 'detail': '평균 7.1시간. 취침/기상 시간 규칙적 (22:30~06:00)'},
      {'icon': '🧠', 'title': '인지 기능', 'status': '정상', 'color': const Color(0xFF16A34A), 'detail': '음성 분석 점수 92점. 발화 속도·발음 정확도 정상'},
      {'icon': '💊', 'title': '복약', 'status': '주의', 'color': const Color(0xFFF59E0B), 'detail': '주 3회 미복용 감지. 비타민D 복용률 57%'},
      {'icon': '😊', 'title': '정서 상태', 'status': '양호', 'color': const Color(0xFF16A34A), 'detail': 'AI 대화 감정 분석 긍정 78%, 중립 18%, 부정 4%'},
    ];

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFF3EEFF), Colors.white]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('📋 주간 건강 리포트', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF7C3AED))),
                  Text('2월 17일 ~ 23일', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('✅ 종합 평가: 양호', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1B6B4A))),
                    SizedBox(height: 6),
                    Text('이번 주 전반적으로 안정적인 상태입니다. 평균 걸음수 3,943보로 전주 대비 9.5% 증가했습니다.',
                      style: TextStyle(fontSize: 13, height: 1.6)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        for (var item in items) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${item['icon']} ${item['title']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: (item['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(item['status'] as String, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: item['color'] as Color)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(item['detail'] as String, style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  // ===== 돌봄 관리 탭 =====
  Widget _buildCareManagement() {
    return Column(
      children: [
        // 요양보호사 카드
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFE8F5EE), Colors.white]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('👩‍⚕️ 담당 요양보호사', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1B6B4A))),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)]),
                    ),
                    child: const Center(child: Text('👩', style: TextStyle(fontSize: 24))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('박미영 요양보호사', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text('경력 8년 · 치매 전문 · ⭐ 4.9', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        const SizedBox(height: 2),
                        const Text('다음 방문: 내일 오전 10시', style: TextStyle(fontSize: 12, color: Color(0xFF1B6B4A), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 케어 일지
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('📝 최근 케어 일지', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              for (var log in [
                {'date': '2/22 (토)', 'note': '혈압 130/82. 점심 식사 정상. 30분 실내 체조 진행.'},
                {'date': '2/20 (목)', 'note': '혈압 135/85. 외출 산책 20분. 무릎 통증 약간 호소.'},
                {'date': '2/18 (화)', 'note': '혈압 128/80. 식사량 양호. TV 시청 중 졸음.'},
              ]) ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[100]!))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(log['date']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
                      const SizedBox(height: 3),
                      Text(log['note']!, style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.5)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 액션 버튼
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.videocam, size: 20),
                label: const Text('영상통화'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B6B4A), foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.message, size: 20),
                label: const Text('메시지'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
