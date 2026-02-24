import { Router, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { authenticate, AuthRequest } from '../middleware/auth';
import { AppError } from '../middleware/errorHandler';
import { generateWeeklyReport } from '../services/ai';

export const reportRouter = Router();
reportRouter.use(authenticate);

function getPrisma(req: any): PrismaClient { return req.app.locals.prisma; }

// POST /api/reports/generate/:seniorId - 주간 리포트 생성
reportRouter.post('/generate/:seniorId', async (req: AuthRequest, res: Response, next) => {
  try {
    const prisma = getPrisma(req);
    const { seniorId } = req.params;

    const weekEnd = new Date();
    const weekStart = new Date();
    weekStart.setDate(weekStart.getDate() - 7);
    weekStart.setHours(0, 0, 0, 0);

    // 이미 존재하는 리포트 확인
    const existing = await prisma.weeklyReport.findUnique({
      where: { seniorId_weekStart: { seniorId, weekStart } },
    });
    if (existing) return res.json(existing);

    // 데이터 수집
    const deviceData = await prisma.deviceData.findMany({
      where: { seniorId, date: { gte: weekStart, lte: weekEnd } },
    });

    const medLogs = await prisma.medicationLog.findMany({
      where: { alert: { seniorId }, scheduledAt: { gte: weekStart, lte: weekEnd } },
    });

    const conversations = await prisma.conversation.findMany({
      where: { seniorId, startedAt: { gte: weekStart, lte: weekEnd }, endedAt: { not: null } },
    });

    // 통계 계산
    const avgSteps = deviceData.length > 0
      ? deviceData.reduce((s, d) => s + d.steps, 0) / deviceData.length : null;
    const avgSleep = deviceData.filter(d => d.sleepHours).length > 0
      ? deviceData.filter(d => d.sleepHours).reduce((s, d) => s + (d.sleepHours || 0), 0) / deviceData.filter(d => d.sleepHours).length : null;
    const medicationRate = medLogs.length > 0
      ? medLogs.filter(l => l.status === 'TAKEN').length / medLogs.length : null;

    // 기분 트렌드
    const moods = conversations.filter(c => c.mood).map(c => c.mood!);
    const moodMap: Record<string, number> = { VERY_GOOD: 5, GOOD: 4, NEUTRAL: 3, BAD: 2, VERY_BAD: 1 };
    const avgMood = moods.length > 0 ? moods.reduce((s, m) => s + (moodMap[m] || 3), 0) / moods.length : 3;
    const moodTrend = avgMood >= 3.5 ? 'improving' : avgMood >= 2.5 ? 'stable' : 'declining';

    // 주의 사항 수집
    const concerns = conversations.flatMap(c => c.concerns || []);
    const uniqueConcerns = [...new Set(concerns)];

    // AI 리포트 생성
    const summary = await generateWeeklyReport(prisma, seniorId, weekStart, weekEnd);

    // 전체 상태 판정
    let overallStatus: 'NORMAL' | 'CAUTION' | 'WARNING' | 'CRITICAL' = 'NORMAL';
    if (uniqueConcerns.length > 3 || (medicationRate !== null && medicationRate < 0.5)) overallStatus = 'WARNING';
    else if (uniqueConcerns.length > 1 || moodTrend === 'declining') overallStatus = 'CAUTION';

    const report = await prisma.weeklyReport.create({
      data: {
        seniorId, weekStart, weekEnd, summary,
        avgSteps, avgSleep, moodTrend, medicationRate,
        concerns: uniqueConcerns,
        recommendations: [],
        overallStatus,
      },
    });

    res.status(201).json(report);
  } catch (err) { next(err); }
});

// GET /api/reports/:seniorId - 리포트 목록
reportRouter.get('/:seniorId', async (req: AuthRequest, res: Response, next) => {
  try {
    const prisma = getPrisma(req);
    const { seniorId } = req.params;

    const reports = await prisma.weeklyReport.findMany({
      where: { seniorId },
      orderBy: { weekStart: 'desc' },
      take: 12,
    });

    res.json(reports);
  } catch (err) { next(err); }
});

// GET /api/reports/:seniorId/latest - 최신 리포트
reportRouter.get('/:seniorId/latest', async (req: AuthRequest, res: Response, next) => {
  try {
    const prisma = getPrisma(req);
    const { seniorId } = req.params;

    const report = await prisma.weeklyReport.findFirst({
      where: { seniorId },
      orderBy: { weekStart: 'desc' },
    });

    if (!report) throw new AppError('아직 생성된 리포트가 없습니다.', 404);
    res.json(report);
  } catch (err) { next(err); }
});
