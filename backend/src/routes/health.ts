import { Router, Response } from 'express';
import { z } from 'zod';
import { PrismaClient } from '@prisma/client';
import { authenticate, AuthRequest } from '../middleware/auth';
import { AppError } from '../middleware/errorHandler';
import { notifyFamilyMembers } from '../services/notification';

export const healthRouter = Router();

function getPrisma(req: any): PrismaClient { return req.app.locals.prisma; }

const deviceDataSchema = z.object({
  seniorId: z.string(),
  steps: z.number().int().min(0).default(0),
  sleepHours: z.number().min(0).max(24).optional(),
  activeMinutes: z.number().int().min(0).optional(),
  screenTime: z.number().int().min(0).optional(),
  appUsageCount: z.number().int().min(0).optional(),
  batteryLevel: z.number().int().min(0).max(100).optional(),
});

// POST /api/health/device-data - 앱에서 센서 데이터 전송 (매일)
healthRouter.post('/device-data', async (req, res: Response, next) => {
  try {
    const prisma = getPrisma(req);
    const data = deviceDataSchema.parse(req.body);
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const record = await prisma.deviceData.upsert({
      where: { seniorId_date: { seniorId: data.seniorId, date: today } },
      update: {
        steps: data.steps,
        sleepHours: data.sleepHours,
        activeMinutes: data.activeMinutes,
        screenTime: data.screenTime,
        appUsageCount: data.appUsageCount,
        batteryLevel: data.batteryLevel,
      },
      create: { ...data, date: today },
    });

    // 이상 징후 체크
    await checkHealthAlerts(prisma, data.seniorId, record);

    res.json(record);
  } catch (err) { next(err); }
});

// GET /api/health/:seniorId/today - 오늘 데이터
healthRouter.get('/:seniorId/today', authenticate, async (req: AuthRequest, res: Response, next) => {
  try {
    const prisma = getPrisma(req);
    const { seniorId } = req.params;

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const data = await prisma.deviceData.findUnique({
      where: { seniorId_date: { seniorId, date: today } },
    });

    // 오늘 대화 요약
    const todayConvo = await prisma.conversation.findFirst({
      where: { seniorId, startedAt: { gte: today } },
      orderBy: { startedAt: 'desc' },
      select: { summary: true, mood: true, concerns: true, startedAt: true },
    });

    // 오늘 복약 상태
    const todayMeds = await prisma.medicationLog.findMany({
      where: { alert: { seniorId }, scheduledAt: { gte: today } },
      include: { alert: { select: { name: true } } },
    });

    res.json({
      deviceData: data,
      conversation: todayConvo,
      medications: todayMeds,
    });
  } catch (err) { next(err); }
});

// GET /api/health/:seniorId/weekly - 주간 데이터
healthRouter.get('/:seniorId/weekly', authenticate, async (req: AuthRequest, res: Response, next) => {
  try {
    const prisma = getPrisma(req);
    const { seniorId } = req.params;

    const weekAgo = new Date();
    weekAgo.setDate(weekAgo.getDate() - 7);
    weekAgo.setHours(0, 0, 0, 0);

    const data = await prisma.deviceData.findMany({
      where: { seniorId, date: { gte: weekAgo } },
      orderBy: { date: 'asc' },
    });

    const conversations = await prisma.conversation.findMany({
      where: { seniorId, startedAt: { gte: weekAgo }, endedAt: { not: null } },
      select: { startedAt: true, mood: true, summary: true },
      orderBy: { startedAt: 'asc' },
    });

    // 통계 계산
    const avgSteps = data.length > 0 ? data.reduce((s, d) => s + d.steps, 0) / data.length : 0;
    const avgSleep = data.filter(d => d.sleepHours).length > 0
      ? data.filter(d => d.sleepHours).reduce((s, d) => s + (d.sleepHours || 0), 0) / data.filter(d => d.sleepHours).length
      : null;

    res.json({
      daily: data,
      conversations,
      stats: {
        avgSteps: Math.round(avgSteps),
        avgSleep: avgSleep ? Math.round(avgSleep * 10) / 10 : null,
        totalConversations: conversations.length,
        daysWithData: data.length,
      },
    });
  } catch (err) { next(err); }
});

// 이상 징후 감지 및 알림
async function checkHealthAlerts(prisma: PrismaClient, seniorId: string, today: any) {
  // 지난 7일 평균 걸음수
  const weekAgo = new Date();
  weekAgo.setDate(weekAgo.getDate() - 7);

  const recentData = await prisma.deviceData.findMany({
    where: { seniorId, date: { gte: weekAgo } },
    select: { steps: true },
  });

  if (recentData.length < 3) return; // 데이터 부족

  const avgSteps = recentData.reduce((s, d) => s + d.steps, 0) / recentData.length;

  // 활동량 급감 감지 (평소 대비 50% 이하)
  if (today.steps < avgSteps * 0.5 && today.steps < 1000) {
    const senior = await prisma.senior.findUnique({ where: { id: seniorId } });
    if (senior) {
      await notifyFamilyMembers(
        prisma, seniorId, 'HEALTH_ALERT',
        `⚠️ ${senior.name} 어르신 활동량 감소`,
        `오늘 걸음수 ${today.steps}보로 평소(${Math.round(avgSteps)}보) 대비 크게 감소했습니다.`,
        { type: 'low_activity', steps: today.steps, avgSteps: Math.round(avgSteps) }
      );
    }
  }
}
