import { Router, Response } from 'express';
import { z } from 'zod';
import { PrismaClient } from '@prisma/client';
import { authenticate, AuthRequest } from '../middleware/auth';
import { AppError } from '../middleware/errorHandler';

export const medicationRouter = Router();
medicationRouter.use(authenticate);

function getPrisma(req: any): PrismaClient { return req.app.locals.prisma; }

const createAlertSchema = z.object({
  seniorId: z.string(),
  name: z.string().min(1),
  dosage: z.string().optional(),
  scheduleTime: z.string().regex(/^\d{2}:\d{2}$/),
  days: z.array(z.string()).default(['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']),
});

// POST /api/medications/alerts - 약 알림 등록
medicationRouter.post('/alerts', async (req: AuthRequest, res: Response, next) => {
  try {
    const prisma = getPrisma(req);
    const data = createAlertSchema.parse(req.body);

    const alert = await prisma.medicationAlert.create({ data });
    res.status(201).json(alert);
  } catch (err) { next(err); }
});

// GET /api/medications/:seniorId/alerts - 약 알림 목록
medicationRouter.get('/:seniorId/alerts', async (req: AuthRequest, res: Response, next) => {
  try {
    const prisma = getPrisma(req);
    const { seniorId } = req.params;

    const alerts = await prisma.medicationAlert.findMany({
      where: { seniorId, isActive: true },
      orderBy: { scheduleTime: 'asc' },
    });

    res.json(alerts);
  } catch (err) { next(err); }
});

// POST /api/medications/log - 복약 기록 (부모님 앱에서 '먹었어요' 버튼)
medicationRouter.post('/log', async (req, res: Response, next) => {
  try {
    const prisma = getPrisma(req);
    const { alertId, status } = req.body; // status: TAKEN, SKIPPED

    const log = await prisma.medicationLog.create({
      data: {
        alertId,
        status: status || 'TAKEN',
        takenAt: status === 'TAKEN' ? new Date() : null,
        scheduledAt: new Date(),
      },
    });

    res.json(log);
  } catch (err) { next(err); }
});

// GET /api/medications/:seniorId/today - 오늘 복약 현황
medicationRouter.get('/:seniorId/today', async (req: AuthRequest, res: Response, next) => {
  try {
    const prisma = getPrisma(req);
    const { seniorId } = req.params;

    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const alerts = await prisma.medicationAlert.findMany({
      where: { seniorId, isActive: true },
      include: {
        logs: {
          where: { scheduledAt: { gte: today, lt: tomorrow } },
          orderBy: { createdAt: 'desc' },
          take: 1,
        },
      },
    });

    const result = alerts.map(alert => ({
      id: alert.id,
      name: alert.name,
      dosage: alert.dosage,
      scheduleTime: alert.scheduleTime,
      status: alert.logs[0]?.status || 'PENDING',
      takenAt: alert.logs[0]?.takenAt,
    }));

    res.json(result);
  } catch (err) { next(err); }
});
