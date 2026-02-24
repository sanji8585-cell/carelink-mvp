import { Router, Request, Response } from 'express';
import Anthropic from '@anthropic-ai/sdk';
import { logger } from '../config/logger';

export const demoRouter = Router();

const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

const DEMO_SYSTEM_PROMPT = `당신은 '케어링크'의 AI 말벗입니다. 어르신과 따뜻하고 자연스러운 대화를 나눕니다.

## 대화 방식
- 이것은 **텍스트 채팅**입니다. 어르신이 스마트폰으로 글자를 입력하여 대화합니다.
- 음성 통화가 아니므로, "잘 안 들려요", "다시 말씀해주세요", "목소리가 안 들려요" 등 음성/청각 관련 표현을 절대 사용하지 마세요.
- 텍스트가 이해하기 어려울 때는 "다시 한번 적어주시겠어요?" 처럼 텍스트에 맞는 표현을 사용하세요.

## 핵심 원칙
- 존댓말 사용 (어르신에게 경어)
- 따뜻하고 친근한 말투, 천천히 쉬운 단어로
- 자연스럽게 건강 상태를 파악 (직접 묻기보다 대화 속에서)
- 약 복용 여부 자연스럽게 확인
- 걱정되는 내용이 있으면 대화 속에서 부드럽게 확인

## 확인할 항목 (자연스럽게)
1. 오늘 기분/컨디션
2. 식사 여부
3. 약 복용 여부
4. 수면 상태
5. 외출/산책 여부
6. 통증이나 불편함
7. 외로움/우울감

## 주의사항
- 의료 진단이나 처방은 절대 하지 않음
- 심각한 증상 호소 시 "자녀분께 알려드릴까요?" 또는 "병원 방문을 권해드려요"
- 반복 질문 피하기, 어르신 말씀에 공감하며 반응

## 응답 형식
- 짧고 간결하게 (1~3문장)
- 어르신이 이해하기 쉬운 단어 사용
- 이모지 최소 사용 (필요 시 1개 정도)`;

// In-memory conversation history for demo sessions
const demoConversations = new Map<string, Array<{ role: 'user' | 'assistant'; content: string }>>();

setInterval(() => { demoConversations.clear(); }, 30 * 60 * 1000);

// POST /api/demo/chat
demoRouter.post('/chat', async (req: Request, res: Response) => {
  try {
    const { message, seniorName } = req.body;
    if (!message || typeof message !== 'string') {
      return res.status(400).json({ error: '메시지가 필요합니다.' });
    }

    const sessionId = (req.headers['x-demo-session'] as string) || 'default';
    if (!demoConversations.has(sessionId)) {
      demoConversations.set(sessionId, []);
    }
    const history = demoConversations.get(sessionId)!;
    history.push({ role: 'user', content: message });

    const recentHistory = history.slice(-20);
    const name = seniorName || '체험자';

    const response = await anthropic.messages.create({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 300,
      system: DEMO_SYSTEM_PROMPT.replace(/어르신/g, `${name} 어르신`),
      messages: recentHistory,
    });

    const aiText = response.content
      .filter(block => block.type === 'text')
      .map(block => (block as any).text)
      .join('');

    history.push({ role: 'assistant', content: aiText });
    res.json({ response: aiText, sessionId });
  } catch (error) {
    logger.error('Demo chat error:', error);
    res.status(500).json({
      response: '죄송해요, 잠시 연결이 불안정하네요. 다시 말씀해주실 수 있으세요?',
    });
  }
});

// GET /api/demo/dashboard
demoRouter.get('/dashboard', async (_req: Request, res: Response) => {
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());

  const weeklyData = [];
  for (let i = 6; i >= 0; i--) {
    const date = new Date(today);
    date.setDate(date.getDate() - i);
    weeklyData.push({
      date: date.toISOString().split('T')[0],
      dayLabel: ['일','월','화','수','목','금','토'][date.getDay()],
      steps: 3200 + Math.floor(Math.random() * 2000),
      sleepHours: parseFloat((5.5 + Math.random() * 2).toFixed(1)),
    });
  }

  res.json({
    senior: { name: '김영순', age: 78, gender: 'female', profileNote: '고혈압, 당뇨 관리 중. 무릎 관절 주의.' },
    todayMood: 'GOOD',
    lastActive: '2시간 전',
    weekly: { data: weeklyData, avgSteps: Math.round(weeklyData.reduce((s, d) => s + d.steps, 0) / 7), avgSleep: parseFloat((weeklyData.reduce((s, d) => s + d.sleepHours, 0) / 7).toFixed(1)) },
    medications: [
      { name: '혈압약 (아모디핀)', time: '08:00', status: 'TAKEN' },
      { name: '당뇨약 (메트포르민)', time: '08:00', status: 'TAKEN' },
      { name: '비타민D', time: '12:00', status: 'PENDING' },
    ],
    medicationCompliance: 0.85,
    recentConversations: [
      { date: '오늘', summary: '아침 산책을 다녀오셨고 컨디션이 좋다고 하심. 약도 제때 복용.', mood: 'GOOD', concerns: [] },
      { date: '어제', summary: '딸과 전화 통화를 하셔서 기뻐하심. 수면 6시간, 소화 약간 불편.', mood: 'GOOD', concerns: [] },
      { date: '2일 전', summary: '비가 와서 산책 못하셔서 답답해하심. 무릎 통증, 식욕 저하.', mood: 'NEUTRAL', concerns: ['무릎 통증', '식욕 저하'] },
    ],
    sosEvents: [{ type: '낙상 감지', date: '3일 전', resolved: true, resolvedBy: '김민지 (딸)' }],
    weeklyReport: '지난 한 주 전반적으로 양호. 일평균 4,200보(목표 84%), 평균 수면 6.5시간. 복약 이행률 85%. 무릎 통증 간헐적 호소 - 정기검진 시 상담 권장.',
  });
});

// GET /api/demo/senior-profile
demoRouter.get('/senior-profile', async (_req: Request, res: Response) => {
  res.json({
    name: '김영순', age: 78, gender: 'female', phone: '010-****-5678',
    conditions: ['고혈압', '제2형 당뇨', '퇴행성 관절염'],
    family: [
      { name: '김민지', relationship: '딸', isPrimary: true },
      { name: '김철수', relationship: '아들', isPrimary: false },
    ],
  });
});
