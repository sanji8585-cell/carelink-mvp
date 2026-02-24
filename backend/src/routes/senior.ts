import { Router, Response } from 'express';
import { z } from 'zod';
import { PrismaClient } from '@prisma/client';
import { authenticate, AuthRequest } from '../middleware/auth';
import { AppError } from '../middleware/errorHandler';

export const seniorRouter = Router();
seniorRouter.use(authenticate);

function getPrisma(req: any): PrismaClient { return req.app.locals.prisma; }

const registerSeniorSchema = z.object({
  name: z.string().min(1),
  birthDate: z.string().optional(),
  gender: z.enum(['MALE', 'FEMALE']).optional(),
  phone: z.string().optional(),
  profileNote: z.string().optional(),
});

// POST /api/seniors - 부모님 등록 (자녀가 등록)
seniorRouter.post('/', async (req: AuthRequest, res: Response, next) => {
  try {
    const prisma = getPrisma(req);
    const data = registerSeniorSchema.parse(req.body);

    const senior = await prisma.senior.create({
      data: {
        name: data.name,
        birthDate: data.birthDate ? new Date(data.birthDate) : undefined,
        gender: data.gender,
        phone: data.phone,
        profileNote: data.profileNote,
        familyLinks: {
          create: { familyId: req.user!.id, role: 'CHILD', isPrimary: true },
        },
      },
      include: { familyLinks: true },
    });

    res.status(201).json({
      ...senior,
      inviteCode: senior.inviteCode, // 다른 가족 초대용 코드
    });
  } catch (err) { next(err); }
});

// POST /api/seniors/link - 초대 코드로 부모님 연결
seniorRouter.post('/link', async (req: AuthRequest, res: Response, next) => {
  try {
    const prisma = getPrisma(req);
    const { inviteCode, role } = req.body;

    const senior = await prisma.senior.findUnique({ where: { inviteCode } });
    if (!senior) throw new AppError('올바르지 않은 초대 코드입니다.', 404);

    const existing = await prisma.seniorFamilyLink.findUnique({
      where: { seniorId_familyId: { seniorId: senior.id, familyId: req.user!.id } },
    });
    if (existing) throw new AppError('이미 연결된 부모님입니다.', 409);

    await prisma.seniorFamilyLink.create({
      data: { seniorId: senior.id, familyId: req.user!.id, role: role || 'CHILD' },
    });

    res.json({ success: true, senior: { id: senior.id, name: senior.name } });
  } catch (err) { next(err); }
});

// GET /api/seniors - 내 부모님 목록
seniorRouter.get('/', async (req: AuthRequest, res: Response, next) => {
  try {
    const prisma = getPrisma(req);
    const links = await prisma.seniorFamilyLink.findMany({
      where: { familyId: req.user!.id },
      include: {
        senior: {
          include: {
            _count: { select: { conversations: true, sosEvents: true } },
          },
        },
      },
    });

    const seniors = links.map(link => ({
      ...link.senior,
      myRole: link.role,
      isPrimary: link.isPrimary,
    }));

    res.json(seniors);
  } catch (err) { next(err); }
});

// GET /api/seniors/:id - 부모님 상세 정보
seniorRouter.get('/:id', async (req: AuthRequest, res: Response, next) => {
  try {
    const prisma = getPrisma(req);
    const { id } = req.params;

    // 권한 확인
    const link = await prisma.seniorFamilyLink.findUnique({
      where: { seniorId_familyId: { seniorId: id, familyId: req.user!.id } },
    });
    if (!link) throw new AppError('접근 권한이 없습니다.', 403);

    const senior = await prisma.senior.findUnique({
      where: { id },
      include: {
        familyLinks: { include: { family: { select: { id: true, name: true, email: true } } } },
        medicationAlerts: { where: { isActive: true } },
      },
    });

    res.json(senior);
  } catch (err) { next(err); }
});
