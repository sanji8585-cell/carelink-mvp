import { Router, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { authenticate, AuthRequest } from '../middleware/auth';

export const notificationRouter = Router();
notificationRouter.use(authenticate);

function getPrisma(req: any): PrismaClient { return req.app.locals.prisma; }

// GET /api/notifications - 내 알림 목록
notificationRouter.get('/', async (req: AuthRequest, res: Response, next) => {
  try {
    const prisma = getPrisma(req);
    const { page = '1', limit = '30', unreadOnly } = req.query;

    const where: any = { userId: req.user!.id };
    if (unreadOnly === 'true') where.isRead = false;

    const skip = (Number(page) - 1) * Number(limit);
    const [notifications, total] = await Promise.all([
      prisma.notification.findMany({
        where, orderBy: { createdAt: 'desc' }, skip, take: Number(limit),
      }),
      prisma.notification.count({ where }),
    ]);

    res.json({ notifications, total, unreadCount: await prisma.notification.count({ where: { userId: req.user!.id, isRead: false } }) });
  } catch (err) { next(err); }
});

// PUT /api/notifications/:id/read - 읽음 처리
notificationRouter.put('/:id/read', async (req: AuthRequest, res: Response, next) => {
  try {
    const prisma = getPrisma(req);
    await prisma.notification.update({
      where: { id: req.params.id },
      data: { isRead: true },
    });
    res.json({ success: true });
  } catch (err) { next(err); }
});

// PUT /api/notifications/read-all - 모두 읽음
notificationRouter.put('/read-all', async (req: AuthRequest, res: Response, next) => {
  try {
    const prisma = getPrisma(req);
    await prisma.notification.updateMany({
      where: { userId: req.user!.id, isRead: false },
      data: { isRead: true },
    });
    res.json({ success: true });
  } catch (err) { next(err); }
});
