-- CreateEnum
CREATE TYPE "Role" AS ENUM ('REQUESTER', 'RUNNER');

-- CreateEnum
CREATE TYPE "ErrandStatus" AS ENUM ('OPEN', 'ACCEPTED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED');

-- CreateTable
CREATE TABLE "User" (
    "id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "role" "Role" NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Errand" (
    "id" UUID NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "pickupAddress" TEXT NOT NULL,
    "dropoffAddress" TEXT NOT NULL,
    "status" "ErrandStatus" NOT NULL DEFAULT 'OPEN',
    "requesterId" UUID NOT NULL,
    "runnerId" UUID,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Errand_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE INDEX "Errand_status_createdAt_idx" ON "Errand"("status", "createdAt");

-- CreateIndex
CREATE INDEX "Errand_requesterId_idx" ON "Errand"("requesterId");

-- CreateIndex
CREATE INDEX "Errand_runnerId_idx" ON "Errand"("runnerId");

-- AddForeignKey
ALTER TABLE "Errand" ADD CONSTRAINT "Errand_requesterId_fkey" FOREIGN KEY ("requesterId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Errand" ADD CONSTRAINT "Errand_runnerId_fkey" FOREIGN KEY ("runnerId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
