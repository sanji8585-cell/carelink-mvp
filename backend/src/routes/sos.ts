import { Router, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { authenticate, AuthRequest } from '../middleware/auth';
import { AppError } from '../middleware/errorHandler';
import { sendSosAlert } from '../services/notification';

export const sosRouter = Router();

function getPrisma(req: any): PrismaClient { return req.app.locals.prisma; }

// POST /api/sos/trigger - SOS 발동 (부모님 앱)
sosRouter.post('/trigger', async (req, res: Response, next) => {
  try {
    const prisma = getPrisma(req);
    const { seniorId, type = 'MANUAL', latitude, longitude } = req.body;

    if (!seniorId) throw new AppError('seniorId가 필요합니다.', 400);

    const event = await prisma.sosEvent.create({
      data: { seniorId, type, latitude, longitude },
    });

    // 모든 가족에게 긴급 알림
    await sendSosAlert(prisma, seniorId, type, latitude && longitude ? { lat: latitude, lng: longitude } : undefined);

    res.status(201).json(event);
  } catch (err) { next(err); }
});

// PUT /api/sos/:id/resolve - SOS 해제 (자녀 앱)
sosRouter.put('/:id/resolve', authenticate, async (req: AuthRequest, res: Response, next) => {
  try {
    const prisma = getPrisma(req);
    const { id } = req.params;
    const { note } = req.body;

    const event = await prisma.sosEvent.update({
      where: { id },
      data: { resolved: true, resolvedAt: new Date(), resolvedBy: req.user!.id, note },
    });

    res.json(event);
  } catch (err) { next(err); }
});

// GET /api/sos/senior/:seniorId - SOS 이벤트 목록
sosRouter.get('/senior/:seniorId', authenticate, async (req: AuthRequest, res: Response, next) => {
  try {
    const prisma = getPrisma(req);
    const { seniorId } = req.params;

    const events = await prisma.sosEvent.findMany({
      where: { seniorId },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });

    res.json(events);
  } catch (err) { next(err); }
});
