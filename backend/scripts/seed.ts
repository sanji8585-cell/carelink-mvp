import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function seed() {
  console.log('🌱 Seeding CareLink database...');

  // 1. 자녀(보호자) 계정
  const passwordHash = await bcrypt.hash('test1234', 12);

  const family1 = await prisma.user.upsert({
    where: { email: 'kim.minjun@example.com' },
    update: {},
    create: {
      email: 'kim.minjun@example.com',
      passwordHash,
      name: '김민준',
      phone: '010-1234-5678',
      role: 'FAMILY',
    },
  });

  const family2 = await prisma.user.upsert({
    where: { email: 'kim.soyeon@example.com' },
    update: {},
    create: {
      email: 'kim.soyeon@example.com',
      passwordHash,
      name: '김소연',
      phone: '010-9876-5432',
      role: 'FAMILY',
    },
  });

  console.log('✅ Users created');

  // 2. 부모님(시니어) 등록
  const senior = await prisma.senior.upsert({
    where: { inviteCode: 'TEST-SENIOR-001' },
    update: {},
    create: {
      name: '김순자',
      birthDate: new Date('1948-03-15'),
      gender: 'FEMALE',
      phone: '010-5555-1234',
      inviteCode: 'TEST-SENIOR-001',
      profileNote: '고혈압, 당뇨 관리 중. 무릎 관절염.',
    },
  });

  console.log('✅ Senior created');

  // 3. 가족 연결
  await prisma.seniorFamilyLink.upsert({
    where: { seniorId_familyId: { seniorId: senior.id, familyId: family1.id } },
    update: {},
    create: { seniorId: senior.id, familyId: family1.id, role: 'CHILD', isPrimary: true },
  });

  await prisma.seniorFamilyLink.upsert({
    where: { seniorId_familyId: { seniorId: senior.id, familyId: family2.id } },
    update: {},
    create: { seniorId: senior.id, familyId: family2.id, role: 'CHILD' },
  });

  console.log('✅ Family links created');

  // 4. 약 알림 등록
  const med1 = await prisma.medicationAlert.create({
    data: { seniorId: senior.id, name: '혈압약 (아모디핀)', dosage: '5mg', scheduleTime: '08:00' },
  });

  const med2 = await prisma.medicationAlert.create({
    data: { seniorId: senior.id, name: '당뇨약 (메트포르민)', dosage: '500mg', scheduleTime: '08:00' },
  });

  const med3 = await prisma.medicationAlert.create({
    data: { seniorId: senior.id, name: '비타민D', dosage: '1000IU', scheduleTime: '12:00' },
  });

  console.log('✅ Medication alerts created');

  // 5. 지난 7일 건강 데이터 생성
  const now = new Date();
  for (let i = 6; i >= 0; i--) {
    const date = new Date(now);
    date.setDate(date.getDate() - i);
    date.setHours(0, 0, 0, 0);

    const steps = Math.floor(2500 + Math.random() * 3000);
    const sleepHours = Math.round((6 + Math.random() * 2) * 10) / 10;

    await prisma.deviceData.upsert({
      where: { seniorId_date: { seniorId: senior.id, date } },
      update: { steps, sleepHours },
      create: {
        seniorId: senior.id,
        date,
        steps,
        sleepHours,
        activeMinutes: Math.floor(30 + Math.random() * 60),
        screenTime: Math.floor(60 + Math.random() * 120),
        appUsageCount: Math.floor(5 + Math.random() * 15),
        batteryLevel: Math.floor(30 + Math.random() * 70),
      },
    });

    // 복약 기록 (80% 확률로 복용)
    for (const med of [med1, med2, med3]) {
      const taken = Math.random() > 0.2;
      const scheduledAt = new Date(date);
      scheduledAt.setHours(parseInt(med.scheduleTime.split(':')[0]));

      await prisma.medicationLog.create({
        data: {
          alertId: med.id,
          status: taken ? 'TAKEN' : 'MISSED',
          takenAt: taken ? scheduledAt : null,
          scheduledAt,
        },
      });
    }
  }

  console.log('✅ 7-day health data created');

  // 6. 샘플 대화 생성
  const convo = await prisma.conversation.create({
    data: {
      seniorId: senior.id,
      startedAt: new Date(now.getTime() - 2 * 60 * 60 * 1000), // 2시간 전
      endedAt: new Date(now.getTime() - 1.8 * 60 * 60 * 1000),
      summary: '오늘 오후에 산책을 다녀오셨고, 기분이 좋으신 편입니다. 혈압약 복용을 잊으셔서 AI가 안내해드렸습니다. 무릎이 약간 아프다고 하셨지만 걸을 수 있는 정도라고 합니다.',
      mood: 'GOOD',
      concerns: ['혈압약 복용 잊음', '무릎 통증 호소 (경미)'],
    },
  });

  const messages = [
    { role: 'ASSISTANT' as const, content: '김순자 어르신, 안녕하세요! 오늘 하루 어떻게 보내고 계세요?' },
    { role: 'USER' as const, content: '오늘은 날씨가 좋아서 산책 다녀왔어.' },
    { role: 'ASSISTANT' as const, content: '산책 다녀오셨군요! 정말 잘 하셨어요. 날씨 좋은 날 걷는 건 건강에 아주 좋죠. 오늘 약은 드셨나요?' },
    { role: 'USER' as const, content: '아, 맞다. 아직 안 먹었네.' },
    { role: 'ASSISTANT' as const, content: '지금 드시면 딱 좋아요! 혈압약이랑 당뇨약 챙겨드세요. 💊' },
    { role: 'USER' as const, content: '알겠어. 그런데 요즘 무릎이 좀 쑤셔.' },
    { role: 'ASSISTANT' as const, content: '무릎이 좀 불편하시군요. 많이 아프세요, 아니면 걸을 수 있는 정도에요?' },
    { role: 'USER' as const, content: '걸을 수는 있어. 그냥 좀 뻐근해.' },
    { role: 'ASSISTANT' as const, content: '다행이에요. 무릎이 뻐근하실 때는 따뜻한 찜질이 도움이 돼요. 너무 오래 걸으시지 말고 중간중간 쉬어가세요. 다음 병원 가실 때 선생님께 말씀드리면 좋겠어요.' },
  ];

  for (const msg of messages) {
    await prisma.message.create({
      data: { conversationId: convo.id, role: msg.role, content: msg.content },
    });
  }

  console.log('✅ Sample conversation created');

  // 7. 알림 생성
  await prisma.notification.createMany({
    data: [
      {
        userId: family1.id, seniorId: senior.id, type: 'CONVERSATION_SUMMARY',
        title: '💬 오늘 대화에서 주의사항이 감지되었습니다',
        body: '혈압약 복용 잊음, 무릎 통증 호소 (경미)',
      },
      {
        userId: family1.id, seniorId: senior.id, type: 'HEALTH_ALERT',
        title: '⚠️ 김순자 어르신 수요일 활동량 감소',
        body: '수요일 걸음수 2,800보로 평소(3,900보) 대비 28% 감소했습니다.',
      },
    ],
  });

  console.log('✅ Notifications created');

  console.log('\n🎉 Seeding complete!');
  console.log('\n📋 Test accounts:');
  console.log('  자녀1: kim.minjun@example.com / test1234');
  console.log('  자녀2: kim.soyeon@example.com / test1234');
  console.log(`  부모님 초대코드: TEST-SENIOR-001`);
}

seed()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
