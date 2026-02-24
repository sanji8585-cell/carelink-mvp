import { PrismaClient, NotificationType } from '@prisma/client';
import { logger } from '../config/logger';

// FCM은 실제 환경에서 firebase-admin으로 구현
// MVP에서는 DB 저장 + 로그로 대체

export async function sendPushNotification(
  prisma: PrismaClient,
  userId: string,
  seniorId: string | null,
  type: NotificationType,
  title: string,
  body: string,
  data?: Record<string, any>
) {
  try {
    // 1. DB에 알림 저장
    const notification = await prisma.notification.create({
      data: { userId, seniorId, type, title, body, data: data || {} },
    });

    // 2. FCM 푸시 발송 (실제 환경)
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { fcmToken: true, name: true },
    });

    if (user?.fcmToken) {
      // TODO: firebase-admin 연동
      // await admin.messaging().send({
      //   token: user.fcmToken,
      //   notification: { title, body },
      //   data: { type, notificationId: notification.id, ...data },
      // });
      logger.info(`📱 Push sent to ${user.name}: ${title}`);
    } else {
      logger.debug(`No FCM token for user ${userId}, notification saved to DB only`);
    }

    return notification;
  } catch (error) {
    logger.error('Push notification failed:', error);
  }
}

export async function notifyFamilyMembers(
  prisma: PrismaClient,
  seniorId: string,
  type: NotificationType,
  title: string,
  body: string,
  data?: Record<string, any>
) {
  const links = await prisma.seniorFamilyLink.findMany({
    where: { seniorId },
    select: { familyId: true },
  });

  await Promise.all(
    links.map(link =>
      sendPushNotification(prisma, link.familyId, seniorId, type, title, body, data)
    )
  );
}

// SOS 긴급 알림
export async function sendSosAlert(
  prisma: PrismaClient,
  seniorId: string,
  sosType: string,
  location?: { lat: number; lng: number }
) {
  const senior = await prisma.senior.findUnique({ where: { id: seniorId } });
  if (!senior) return;

  const typeLabel = sosType === 'FALL' ? '낙상 감지' : sosType === 'INACTIVITY' ? '장시간 미활동' : '긴급 SOS';

  await notifyFamilyMembers(
    prisma, seniorId, 'SOS',
    `🚨 ${senior.name} 어르신 ${typeLabel}`,
    `${senior.name} 어르신에게 ${typeLabel} 알림이 발생했습니다. 즉시 확인해주세요.`,
    { sosType, location }
  );
}

// 복약 미이행 알림
export async function sendMedicationMissedAlert(
  prisma: PrismaClient,
  seniorId: string,
  medicationName: string
) {
  const senior = await prisma.senior.findUnique({ where: { id: seniorId } });
  if (!senior) return;

  await notifyFamilyMembers(
    prisma, seniorId, 'MEDICATION_MISSED',
    `💊 ${senior.name} 어르신 복약 미확인`,
    `${senior.name} 어르신이 ${medicationName} 복용을 확인하지 않으셨습니다.`,
    { medicationName }
  );
}
