import Anthropic from '@anthropic-ai/sdk';
import { PrismaClient, MoodScore } from '@prisma/client';
import { logger } from '../config/logger';

const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

const SENIOR_SYSTEM_PROMPT = `당신은 '케어링크'의 AI 말벗입니다. 어르신과 따뜻하고 자연스러운 대화를 나눕니다.

## 대화 방식
- 이것은 **텍스트 채팅**입니다. 어르신이 스마트폰으로 글자를 입력하여 대화합니다.
- 음성 통화가 아니므로, "잘 안 들려요", "다시 말씀해주세요", "목소리가 안 들려요" 등 음성/청각 관련 표현을 절대 사용하지 마세요.
- 텍스트가 이해하기 어려울 때는 "다시 한번 적어주시겠어요?" 처럼 텍스트에 맞는 표현을 사용하세요.

## 핵심 원칙
- 존댓말 사용 (어르신에게 경어)
- 따뜻하고 친근한 말투, 천천히 쉬운 단어로
- 자연스럽게 건강 상태를 파악 (직접 묻기보다 대화 속에서)
- 매 대화 시작 시 인사 + 오늘 기분/컨디션 확인
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
- 대화는 5~10분 내외로 자연스럽게 마무리
- 반복 질문 피하기, 어르신 말씀에 공감하며 반응

## 응답 형식
- 짧고 간결하게 (1~3문장)
- 어르신이 이해하기 쉬운 단어 사용
- 이모지 최소 사용 (필요 시 1개 정도)`;

export async function generateAiResponse(
  prisma: PrismaClient,
  conversationId: string,
  seniorMessage: string,
  seniorName: string
): Promise<string> {
  try {
    // 이전 대화 히스토리 가져오기 (최근 20개)
    const history = await prisma.message.findMany({
      where: { conversationId },
      orderBy: { createdAt: 'asc' },
      take: 20,
    });

    const messages = history.map(m => ({
      role: m.role === 'USER' ? 'user' as const : 'assistant' as const,
      content: m.content,
    }));

    // 새 메시지 추가
    messages.push({ role: 'user', content: seniorMessage });

    const response = await anthropic.messages.create({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 300,
      system: SENIOR_SYSTEM_PROMPT.replace('어르신', `${seniorName} 어르신`),
      messages,
    });

    const aiText = response.content
      .filter(block => block.type === 'text')
      .map(block => (block as any).text)
      .join('');

    return aiText;
  } catch (error) {
    logger.error('AI response generation failed:', error);
    return '죄송해요, 잠시 연결이 불안정하네요. 다시 말씀해주실 수 있으세요?';
  }
}

export async function analyzeConversation(
  prisma: PrismaClient,
  conversationId: string
): Promise<{ summary: string; mood: MoodScore; concerns: string[] }> {
  try {
    const messages = await prisma.message.findMany({
      where: { conversationId },
      orderBy: { createdAt: 'asc' },
    });

    const transcript = messages
      .map(m => `${m.role === 'USER' ? '어르신' : 'AI'}: ${m.content}`)
      .join('\n');

    const response = await anthropic.messages.create({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 500,
      system: '대화 내용을 분석하여 JSON으로 응답하세요. 반드시 JSON만 출력하세요.',
      messages: [{
        role: 'user',
        content: `다음 AI 말벗 대화를 분석해주세요:

${transcript}

다음 JSON 형식으로 응답:
{
  "summary": "대화 요약 (2-3문장, 한국어)",
  "mood": "VERY_GOOD|GOOD|NEUTRAL|BAD|VERY_BAD",
  "concerns": ["주의사항1", "주의사항2"],
  "healthNotes": {
    "meal": "식사 여부/상태 또는 null",
    "medication": "복약 여부 또는 null",
    "sleep": "수면 상태 또는 null",
    "pain": "통증/불편 또는 null",
    "activity": "활동/외출 여부 또는 null"
  }
}`,
      }],
    });

    const text = response.content
      .filter(block => block.type === 'text')
      .map(block => (block as any).text)
      .join('');

    const cleaned = text.replace(/```json\n?|\n?```/g, '').trim();
    const parsed = JSON.parse(cleaned);

    return {
      summary: parsed.summary || '대화 요약을 생성하지 못했습니다.',
      mood: parsed.mood || 'NEUTRAL',
      concerns: parsed.concerns || [],
    };
  } catch (error) {
    logger.error('Conversation analysis failed:', error);
    return { summary: '대화 분석 중 오류 발생', mood: 'NEUTRAL' as MoodScore, concerns: [] };
  }
}

export async function generateWeeklyReport(
  prisma: PrismaClient,
  seniorId: string,
  weekStart: Date,
  weekEnd: Date
): Promise<string> {
  // 해당 주의 대화 요약들
  const conversations = await prisma.conversation.findMany({
    where: { seniorId, startedAt: { gte: weekStart, lte: weekEnd } },
    select: { summary: true, mood: true, concerns: true },
  });

  // 건강 데이터
  const deviceData = await prisma.deviceData.findMany({
    where: { seniorId, date: { gte: weekStart, lte: weekEnd } },
    orderBy: { date: 'asc' },
  });

  // 복약 기록
  const medLogs = await prisma.medicationLog.findMany({
    where: {
      alert: { seniorId },
      scheduledAt: { gte: weekStart, lte: weekEnd },
    },
  });

  const context = {
    conversations: conversations.map(c => ({
      summary: c.summary,
      mood: c.mood,
      concerns: c.concerns,
    })),
    deviceData: deviceData.map(d => ({
      date: d.date,
      steps: d.steps,
      sleepHours: d.sleepHours,
    })),
    medicationRate: medLogs.length > 0
      ? medLogs.filter(l => l.status === 'TAKEN').length / medLogs.length
      : null,
  };

  try {
    const response = await anthropic.messages.create({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 800,
      messages: [{
        role: 'user',
        content: `다음 데이터를 기반으로 어르신의 주간 건강 리포트를 작성해주세요.
보호자(자녀)가 읽을 내용이므로, 따뜻하되 핵심 정보가 명확해야 합니다.

데이터: ${JSON.stringify(context)}

다음 형식으로 한국어 리포트를 작성하세요:
1. 종합 평가 (1문장)
2. 활동량 분석 (걸음수 트렌드)
3. 수면 분석
4. 정서 상태 (대화 기반)
5. 복약 이행률
6. 주의 필요 사항
7. 권장 사항`,
      }],
    });

    return response.content
      .filter(block => block.type === 'text')
      .map(block => (block as any).text)
      .join('');
  } catch (error) {
    logger.error('Weekly report generation failed:', error);
    return '주간 리포트 생성 중 오류가 발생했습니다.';
  }
}
