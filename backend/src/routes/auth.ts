import { Router, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { z } from 'zod';
import { PrismaClient } from '@prisma/client';
import { authenticate, AuthRequest } from '../middleware/auth';
import { AppError } from '../middleware/errorHandler';

export const authRouter = Router();

const signupSchema = z.object({
  email: z.string().email('올바른 이메일을 입력해주세요.'),
  password: z.string().min(8, '비밀번호는 8자 이상이어야 합니다.'),
  name: z.string().min(1, '이름을 입력해주세요.'),
  phone: z.string().optional(),
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string(),
});

function getPrisma(req: any): PrismaClient {
  return req.app.locals.prisma;
}

function generateToken(user: { id: string; email: string; role: string }) {
  return jwt.sign(
    { id: user.id, email: user.email, role: user.role },
    process.env.JWT_SECRET!,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );
}

// POST /api/auth/signup - 자녀(보호자) 회원가입
authRouter.post('/signup', async (req, res: Response, next) => {
  try {
    const prisma = getPrisma(req);
    const data = signupSchema.parse(req.body);

    const existing = await prisma.user.findUnique({ where: { email: data.email } });
    if (existing) throw new AppError('이미 가입된 이메일입니다.', 409);

    const passwordHash = await bcrypt.hash(data.password, 12);
    const user = await prisma.user.create({
      data: { email: data.email, passwordHash, name: data.name, phone: data.phone },
    });

    const token = generateToken(user);
    res.status(201).json({
      token,
      user: { id: user.id, email: user.email, name: user.name, role: user.role },
    });
  } catch (err) { next(err); }
});

// POST /api/auth/login
authRouter.post('/login', async (req, res: Response, next) => {
  try {
    const prisma = getPrisma(req);
    const data = loginSchema.parse(req.body);

    const user = await prisma.user.findUnique({ where: { email: data.email } });
    if (!user) throw new AppError('이메일 또는 비밀번호가 올바르지 않습니다.', 401);

    const valid = await bcrypt.compare(data.password, user.passwordHash);
    if (!valid) throw new AppError('이메일 또는 비밀번호가 올바르지 않습니다.', 401);

    const token = generateToken(user);
    res.json({
      token,
      user: { id: user.id, email: user.email, name: user.name, role: user.role },
    });
  } catch (err) { next(err); }
});

// GET /api/auth/me - 내 정보
authRouter.get('/me', authenticate, async (req: AuthRequest, res: Response, next) => {
  try {
    const prisma = getPrisma(req);
    const user = await prisma.user.findUnique({
      where: { id: req.user!.id },
      select: { id: true, email: true, name: true, phone: true, role: true, createdAt: true },
    });
    if (!user) throw new AppError('사용자를 찾을 수 없습니다.', 404);
    res.json(user);
  } catch (err) { next(err); }
});

// PUT /api/auth/fcm-token - FCM 토큰 업데이트
authRouter.put('/fcm-token', authenticate, async (req: AuthRequest, res: Response, next) => {
  try {
    const prisma = getPrisma(req);
    const { fcmToken } = req.body;
    await prisma.user.update({ where: { id: req.user!.id }, data: { fcmToken } });
    res.json({ success: true });
  } catch (err) { next(err); }
});
