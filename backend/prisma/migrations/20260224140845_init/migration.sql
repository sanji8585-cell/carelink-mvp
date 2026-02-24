-- CreateEnum
CREATE TYPE "UserRole" AS ENUM ('FAMILY', 'ADMIN');

-- CreateEnum
CREATE TYPE "Gender" AS ENUM ('MALE', 'FEMALE');

-- CreateEnum
CREATE TYPE "FamilyRole" AS ENUM ('CHILD', 'SPOUSE', 'OTHER');

-- CreateEnum
CREATE TYPE "MessageRole" AS ENUM ('USER', 'ASSISTANT', 'SYSTEM');

-- CreateEnum
CREATE TYPE "MoodScore" AS ENUM ('VERY_GOOD', 'GOOD', 'NEUTRAL', 'BAD', 'VERY_BAD');

-- CreateEnum
CREATE TYPE "HealthDataType" AS ENUM ('STEPS', 'SLEEP_HOURS', 'HEART_RATE', 'BLOOD_PRESSURE_SYS', 'BLOOD_PRESSURE_DIA', 'WEIGHT', 'TEMPERATURE', 'COGNITIVE_SCORE', 'TOUCH_ACCURACY', 'APP_USAGE');

-- CreateEnum
CREATE TYPE "MedicationStatus" AS ENUM ('PENDING', 'TAKEN', 'MISSED', 'SKIPPED');

-- CreateEnum
CREATE TYPE "SosType" AS ENUM ('MANUAL', 'FALL', 'INACTIVITY');

-- CreateEnum
CREATE TYPE "HealthStatus" AS ENUM ('NORMAL', 'CAUTION', 'WARNING', 'CRITICAL');

-- CreateEnum
CREATE TYPE "NotificationType" AS ENUM ('SOS', 'HEALTH_ALERT', 'MEDICATION_MISSED', 'WEEKLY_REPORT', 'CONVERSATION_SUMMARY', 'INACTIVITY', 'SYSTEM');

-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "phone" TEXT,
    "role" "UserRole" NOT NULL DEFAULT 'FAMILY',
    "fcmToken" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "seniors" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "birthDate" TIMESTAMP(3),
    "gender" "Gender",
    "phone" TEXT,
    "inviteCode" TEXT NOT NULL,
    "profileNote" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "seniors_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "senior_family_links" (
    "id" TEXT NOT NULL,
    "seniorId" TEXT NOT NULL,
    "familyId" TEXT NOT NULL,
    "role" "FamilyRole" NOT NULL DEFAULT 'CHILD',
    "isPrimary" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "senior_family_links_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "conversations" (
    "id" TEXT NOT NULL,
    "seniorId" TEXT NOT NULL,
    "startedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "endedAt" TIMESTAMP(3),
    "summary" TEXT,
    "mood" "MoodScore",
    "concerns" TEXT[],

    CONSTRAINT "conversations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "messages" (
    "id" TEXT NOT NULL,
    "conversationId" TEXT NOT NULL,
    "role" "MessageRole" NOT NULL,
    "content" TEXT NOT NULL,
    "audioUrl" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "messages_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "health_records" (
    "id" TEXT NOT NULL,
    "seniorId" TEXT NOT NULL,
    "date" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "type" "HealthDataType" NOT NULL,
    "value" DOUBLE PRECISION NOT NULL,
    "unit" TEXT,
    "metadata" JSONB,
    "source" TEXT NOT NULL DEFAULT 'app',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "health_records_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "device_data" (
    "id" TEXT NOT NULL,
    "seniorId" TEXT NOT NULL,
    "date" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "steps" INTEGER NOT NULL DEFAULT 0,
    "sleepHours" DOUBLE PRECISION,
    "activeMinutes" INTEGER,
    "screenTime" INTEGER,
    "appUsageCount" INTEGER,
    "batteryLevel" INTEGER,
    "metadata" JSONB,

    CONSTRAINT "device_data_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "medication_alerts" (
    "id" TEXT NOT NULL,
    "seniorId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "dosage" TEXT,
    "scheduleTime" TEXT NOT NULL,
    "days" TEXT[],
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "medication_alerts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "medication_logs" (
    "id" TEXT NOT NULL,
    "alertId" TEXT NOT NULL,
    "takenAt" TIMESTAMP(3),
    "status" "MedicationStatus" NOT NULL DEFAULT 'PENDING',
    "scheduledAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "medication_logs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sos_events" (
    "id" TEXT NOT NULL,
    "seniorId" TEXT NOT NULL,
    "type" "SosType" NOT NULL DEFAULT 'MANUAL',
    "latitude" DOUBLE PRECISION,
    "longitude" DOUBLE PRECISION,
    "resolved" BOOLEAN NOT NULL DEFAULT false,
    "resolvedAt" TIMESTAMP(3),
    "resolvedBy" TEXT,
    "note" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "sos_events_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "weekly_reports" (
    "id" TEXT NOT NULL,
    "seniorId" TEXT NOT NULL,
    "weekStart" TIMESTAMP(3) NOT NULL,
    "weekEnd" TIMESTAMP(3) NOT NULL,
    "summary" TEXT NOT NULL,
    "avgSteps" DOUBLE PRECISION,
    "avgSleep" DOUBLE PRECISION,
    "moodTrend" TEXT,
    "medicationRate" DOUBLE PRECISION,
    "concerns" TEXT[],
    "recommendations" TEXT[],
    "cognitiveScore" DOUBLE PRECISION,
    "overallStatus" "HealthStatus" NOT NULL DEFAULT 'NORMAL',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "weekly_reports_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "notifications" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "seniorId" TEXT,
    "type" "NotificationType" NOT NULL,
    "title" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "data" JSONB,
    "isRead" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notifications_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "seniors_inviteCode_key" ON "seniors"("inviteCode");

-- CreateIndex
CREATE UNIQUE INDEX "senior_family_links_seniorId_familyId_key" ON "senior_family_links"("seniorId", "familyId");

-- CreateIndex
CREATE INDEX "health_records_seniorId_date_idx" ON "health_records"("seniorId", "date");

-- CreateIndex
CREATE INDEX "health_records_seniorId_type_date_idx" ON "health_records"("seniorId", "type", "date");

-- CreateIndex
CREATE UNIQUE INDEX "device_data_seniorId_date_key" ON "device_data"("seniorId", "date");

-- CreateIndex
CREATE UNIQUE INDEX "weekly_reports_seniorId_weekStart_key" ON "weekly_reports"("seniorId", "weekStart");

-- CreateIndex
CREATE INDEX "notifications_userId_isRead_idx" ON "notifications"("userId", "isRead");

-- AddForeignKey
ALTER TABLE "senior_family_links" ADD CONSTRAINT "senior_family_links_seniorId_fkey" FOREIGN KEY ("seniorId") REFERENCES "seniors"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "senior_family_links" ADD CONSTRAINT "senior_family_links_familyId_fkey" FOREIGN KEY ("familyId") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "conversations" ADD CONSTRAINT "conversations_seniorId_fkey" FOREIGN KEY ("seniorId") REFERENCES "seniors"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "messages" ADD CONSTRAINT "messages_conversationId_fkey" FOREIGN KEY ("conversationId") REFERENCES "conversations"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "health_records" ADD CONSTRAINT "health_records_seniorId_fkey" FOREIGN KEY ("seniorId") REFERENCES "seniors"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "device_data" ADD CONSTRAINT "device_data_seniorId_fkey" FOREIGN KEY ("seniorId") REFERENCES "seniors"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "medication_alerts" ADD CONSTRAINT "medication_alerts_seniorId_fkey" FOREIGN KEY ("seniorId") REFERENCES "seniors"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "medication_logs" ADD CONSTRAINT "medication_logs_alertId_fkey" FOREIGN KEY ("alertId") REFERENCES "medication_alerts"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sos_events" ADD CONSTRAINT "sos_events_seniorId_fkey" FOREIGN KEY ("seniorId") REFERENCES "seniors"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "weekly_reports" ADD CONSTRAINT "weekly_reports_seniorId_fkey" FOREIGN KEY ("seniorId") REFERENCES "seniors"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
