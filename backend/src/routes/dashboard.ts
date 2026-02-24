import { Router, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { authenticate, AuthRequest } from '../middleware/auth';
import { AppError } from '../middleware/errorHandler';

export const dashboardRouter = Router();
dashboardRouter.use(authenticate);

function getPrisma(req: any): PrismaClient { return req.app.locals.prisma; }

// GET /api/dashboard/:seniorId - 종합 대시보드 (자녀 앱 메인)
dashboardRouter.get('/:seniorId', async (req: AuthRequest, res: Response, next) => {
  try {
    const prisma = getPrisma(req);
    const { seniorId } = req.params;

    // 권한 확인
    const link = await prisma.seniorFamilyLink.findUnique({
      where: { seniorId_familyId: { seniorId, familyId: req.user!.id } },
    });
    if (!link) throw new AppError('접근 권한이 없습니다.', 403);

    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const weekAgo = new Date(today);
    weekAgo.setDate(weekAgo.getDate() - 7);

    // 병렬 쿼리
    const [senior, todayData, weeklyData, lastConvo, todayMeds, latestReport, unresolvedSos, unreadNotifs] = await Promise.all([
      // 부모님 기본 정보
      prisma.senior.findUnique({ where: { id: seniorId }, select: { id: true, name: true, birthDate: true, profileNote: true } }),
      // 오늘 디바이스 데이터
      prisma.deviceData.findUnique({ where: { seniorId_date: { seniorId, date: today } } }),
      // 주간 데이터
      prisma.deviceData.findMany({ where: { seniorId, date: { gte: weekAgo } }, orderBy: { date: 'asc' } }),
      // 최근 대화
      prisma.conversation.findFirst({ where: { seniorId, endedAt: { not: null } }, orderBy: { startedAt: 'desc' }, select: { summary: true, mood: true, concerns: true, startedAt: true } }),
      // 오늘 복약
      prisma.medicationLog.findMany({
        where: { alert: { seniorId }, scheduledAt: { gte: today } },
        include: { alert: { select: { name: true, scheduleTime: true } } },
      }),
      // 최신 주간 리포트
      prisma.weeklyReport.findFirst({ where: { seniorId }, orderBy: { weekStart: 'desc' } }),
      // 미해결 SOS
      prisma.sosEvent.findMany({ where: { seniorId, resolved: false } }),
      // 안 읽은 알림 수
      prisma.notification.count({ where: { userId: req.user!.id, isRead: false } }),
    ]);

    // 오늘 복약 현황 정리
    const medAlerts = await prisma.medicationAlert.findMany({ where: { seniorId, isActive: true } });
    const medStatus = medAlerts.map(alert => {
      const log = todayMeds.find(l => l.alertId === alert.id);
      return {
        name: alert.name, scheduleTime: alert.scheduleTime,
        status: log?.status || 'PENDING',
      };
    });
    const medRate = medStatus.length > 0
      ? medStatus.filter(m => m.status === 'TAKEN').length + '/' + medStatus.length
      : 'N/A';

    // 주간 통계
    const weekSteps = weeklyData.map(d => ({ date: d.date, steps: d.steps, sleep: d.sleepHours }));
    const avgSteps = weeklyData.length > 0
      ? Math.round(weeklyData.reduce((s, d) => s + d.steps, 0) / weeklyData.length) : 0;

    // 상태 판정
    let status: 'normal' | 'caution' | 'warning' | 'critical' = 'normal';
    if (unresolvedSos.length > 0) status = 'critical';
    else if (lastConvo?.concerns && lastConvo.concerns.length > 0) status = 'caution';

    // 마지막 활동 시간 (대화 시간 기준)
    const lastActiveStr = lastConvo?.startedAt
      ? getTimeAgo(lastConvo.startedAt)
      : '대화 기록 없음';

    res.json({
      senior,
      status,
      lastActive: lastActiveStr,
      today: {
        steps: todayData?.steps || 0,
        sleepHours: todayData?.sleepHours,
        medications: medStatus,
        medicationRate: medRate,
        conversation: lastConvo,
      },
      weekly: {
        data: weekSteps,
        avgSteps,
      },
      latestReport: latestReport ? {
        weekStart: latestReport.weekStart,
        overallStatus: latestReport.overallStatus,
        summary: latestReport.summary,
        avgSteps: latestReport.avgSteps,
        avgSleep: latestReport.avgSleep,
        medicationRate: latestReport.medicationRate,
        concerns: latestReport.concerns,
      } : null,
      alerts: {
        unresolvedSos: unresolvedSos.length,
        unreadNotifications: unreadNotifs,
      },
    });
  } catch (err) { next(err); }
});

function getTimeAgo(date: Date): string {
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffMins = Math.floor(diffMs / 60000);

  if (diffMins < 1) return '방금 전';
  if (diffMins < 60) return `${diffMins}분 전`;
  const diffHours = Math.floor(diffMins / 60);
  if (diffHours < 24) return `${diffHours}시간 전`;
  const diffDays = Math.floor(diffHours / 24);
  return `${diffDays}일 전`;
}
