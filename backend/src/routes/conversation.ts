import { Router, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { authenticate, AuthRequest } from '../middleware/auth';
import { AppError } from '../middleware/errorHandler';
import { generateAiResponse, analyzeConversation } from '../services/ai';
import { notifyFamilyMembers } from '../services/notification';

export const conversationRouter = Router();

function getPrisma(req: any): PrismaClient { return req.app.locals.prisma; }

// POST /api/conversations/start - 대화 시작 (부모님 앱에서 호출)
conversationRouter.post('/start', async (req, res: Response, next) => {
  try {
    const prisma = getPrisma(req);
    const { seniorId } = req.body;
    if (!seniorId) throw new AppError('seniorId가 필요합니다.', 400);

    const senior = await prisma.senior.findUnique({ where: { id: seniorId } });
    if (!senior) throw new AppError('어르신 정보를 찾을 수 없습니다.', 404);

    const conversation = await prisma.conversation.create({
      data: { seniorId },
    });

    // AI 첫 인사 메시지 생성
    const hour = new Date().getHours();
    let greeting: string;
    if (hour < 12) greeting = `${senior.name} 어르신, 좋은 아침이에요! 오늘 컨디션은 어떠세요?`;
    else if (hour < 18) greeting = `${senior.name} 어르신, 안녕하세요! 오늘 하루 어떻게 보내고 계세요?`;
    else greeting = `${senior.name} 어르신, 안녕하세요! 오늘 하루 잘 보내셨어요?`;

    await prisma.message.create({
      data: { conversationId: conversation.id, role: 'ASSISTANT', content: greeting },
    });

    res.status(201).json({
      conversationId: conversation.id,
      firstMessage: greeting,
    });
  } catch (err) { next(err); }
});

// POST /api/conversations/:id/message - 메시지 전송
conversationRouter.post('/:id/message', async (req, res: Response, next) => {
  try {
    const prisma = getPrisma(req);
    const { id } = req.params;
    const { content } = req.body;
    if (!content) throw new AppError('메시지 내용이 필요합니다.', 400);

    const conversation = await prisma.conversation.findUnique({
      where: { id },
      include: { senior: true },
    });
    if (!conversation) throw new AppError('대화를 찾을 수 없습니다.', 404);
    if (conversation.endedAt) throw new AppError('이미 종료된 대화입니다.', 400);

    // 사용자 메시지 저장
    await prisma.message.create({
      data: { conversationId: id, role: 'USER', content },
    });

    // AI 응답 생성
    const aiResponse = await generateAiResponse(prisma, id, content, conversation.senior.name);

    // AI 메시지 저장
    await prisma.message.create({
      data: { conversationId: id, role: 'ASSISTANT', content: aiResponse },
    });

    res.json({ response: aiResponse });
  } catch (err) { next(err); }
});

// POST /api/conversations/:id/end - 대화 종료
conversationRouter.post('/:id/end', async (req, res: Response, next) => {
  try {
    const prisma = getPrisma(req);
    const { id } = req.params;

    const conversation = await prisma.conversation.findUnique({ where: { id } });
    if (!conversation) throw new AppError('대화를 찾을 수 없습니다.', 404);

    // AI 분석
    const analysis = await analyzeConversation(prisma, id);

    // 대화 업데이트
    await prisma.conversation.update({
      where: { id },
      data: {
        endedAt: new Date(),
        summary: analysis.summary,
        mood: analysis.mood,
        concerns: analysis.concerns,
      },
    });

    // 주의사항이 있으면 가족에게 알림
    if (analysis.concerns.length > 0) {
      await notifyFamilyMembers(
        prisma, conversation.seniorId, 'CONVERSATION_SUMMARY',
        '💬 오늘 대화에서 주의사항이 감지되었습니다',
        analysis.concerns.join(', '),
        { conversationId: id }
      );
    }

    res.json({ summary: analysis.summary, mood: analysis.mood, concerns: analysis.concerns });
  } catch (err) { next(err); }
});

// GET /api/conversations/senior/:seniorId - 부모님 대화 목록 (자녀가 조회)
conversationRouter.get('/senior/:seniorId', authenticate, async (req: AuthRequest, res: Response, next) => {
  try {
    const prisma = getPrisma(req);
    const { seniorId } = req.params;
    const { page = '1', limit = '20' } = req.query;

    // 권한 확인
    const link = await prisma.seniorFamilyLink.findUnique({
      where: { seniorId_familyId: { seniorId, familyId: req.user!.id } },
    });
    if (!link) throw new AppError('접근 권한이 없습니다.', 403);

    const skip = (Number(page) - 1) * Number(limit);
    const conversations = await prisma.conversation.findMany({
      where: { seniorId },
      orderBy: { startedAt: 'desc' },
      skip,
      take: Number(limit),
      select: {
        id: true, startedAt: true, endedAt: true,
        summary: true, mood: true, concerns: true,
        _count: { select: { messages: true } },
      },
    });

    res.json(conversations);
  } catch (err) { next(err); }
});

// GET /api/conversations/:id/messages - 대화 메시지 조회
conversationRouter.get('/:id/messages', authenticate, async (req: AuthRequest, res: Response, next) => {
  try {
    const prisma = getPrisma(req);
    const { id } = req.params;

    const messages = await prisma.message.findMany({
      where: { conversationId: id },
      orderBy: { createdAt: 'asc' },
      select: { id: true, role: true, content: true, createdAt: true },
    });

    res.json(messages);
  } catch (err) { next(err); }
});
