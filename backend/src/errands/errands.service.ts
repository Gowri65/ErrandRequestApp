
import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import { PrismaService } from '../prisma/prisma.service';
import { CreateErrandDto } from './dto/create-errand.dto';
import { UpdateStatusDto } from './dto/update-status.dto';

import { ErrandStatus } from '../../generated/prisma/enums';

@Injectable()
export class ErrandsService {
  constructor(private prisma: PrismaService) {}

  // Requester creates an errand
  async createErrand(userId: string, dto: CreateErrandDto) {
    return this.prisma.errand.create({
      data: {
        title: dto.title,
        description: dto.description,
        pickupAddress: dto.pickupAddress,
        dropoffAddress: dto.dropoffAddress,
        requesterId: userId,
      },
    });
  }

  // Requester views only their own errands
  async getMyErrands(userId: string) {
    return this.prisma.errand.findMany({
      where: { requesterId: userId },
      orderBy: { createdAt: 'desc' },
      include: {
        runner: {
          select: { id: true, name: true, email: true },
        },
      },
    });
  }

  // Runner views all available errands
  async getOpenErrands() {
    return this.prisma.errand.findMany({
      where: { status: ErrandStatus.OPEN },
      orderBy: { createdAt: 'desc' },
      include: {
        requester: {
          select: { id: true, name: true },
        },
      },
    });
  }

  // Runner views errands assigned to them
  async getAcceptedErrands(runnerId: string) {
    return this.prisma.errand.findMany({
      where: {
        runnerId,
        status: {
          in: [
            ErrandStatus.ACCEPTED,
            ErrandStatus.IN_PROGRESS,
            ErrandStatus.COMPLETED,
          ],
        },
      },
      orderBy: { updatedAt: 'desc' },
      include: {
        requester: {
          select: { id: true, name: true },
        },
      },
    });
  }

  // Runner accepts an errand
  async acceptErrand(runnerId: string, errandId: string) {
    return this.prisma.$transaction(async (tx) => {
      // Lock this runner's user row. Concurrent accept requests
      // from the same runner must wait for one another.
      const lockedRunner = await tx.$queryRaw<Array<{ id: string }>>`
        SELECT "id"
        FROM "User"
        WHERE "id" = ${runnerId}::uuid
        FOR UPDATE
      `;

      if (lockedRunner.length === 0) {
        throw new NotFoundException('Runner not found');
      }

      // A runner can have only one active errand
      const activeErrand = await tx.errand.findFirst({
        where: {
          runnerId,
          status: {
            in: [
              ErrandStatus.ACCEPTED,
              ErrandStatus.IN_PROGRESS,
            ],
          },
        },
      });

      if (activeErrand) {
        throw new ConflictException(
          'You already have an active errand',
        );
      }

      // Conditional update prevents two runners accepting
      // the same errand at the same time.
      const result = await tx.errand.updateMany({
        where: {
          id: errandId,
          status: ErrandStatus.OPEN,
          runnerId: null,
        },
        data: {
          runnerId,
          status: ErrandStatus.ACCEPTED,
        },
      });

      if (result.count === 0) {
        throw new ConflictException(
          'This errand is no longer available',
        );
      }

      return tx.errand.findUnique({
        where: { id: errandId },
        include: {
          requester: {
            select: { id: true, name: true },
          },
        },
      });
    });
  }

  // Requester cancels their own open errand
  async cancelErrand(userId: string, errandId: string) {
    const result = await this.prisma.errand.updateMany({
      where: {
        id: errandId,
        requesterId: userId,
        status: ErrandStatus.OPEN,
      },
      data: {
        status: ErrandStatus.CANCELLED,
      },
    });

    if (result.count === 0) {
      const errand = await this.prisma.errand.findUnique({
        where: { id: errandId },
      });

      if (!errand) {
        throw new NotFoundException('Errand not found');
      }

      if (errand.requesterId !== userId) {
        throw new ForbiddenException(
          'You cannot cancel another requesters errand',
        );
      }

      throw new BadRequestException(
        'Only open errands can be cancelled',
      );
    }

    return this.prisma.errand.findUnique({
      where: { id: errandId },
    });
  }

  // Runner updates status without skipping lifecycle steps
  async updateStatus(
    runnerId: string,
    errandId: string,
    dto: UpdateStatusDto,
  ) {
    let currentStatus: ErrandStatus;

    if (dto.status === ErrandStatus.IN_PROGRESS) {
      currentStatus = ErrandStatus.ACCEPTED;
    } else if (dto.status === ErrandStatus.COMPLETED) {
      currentStatus = ErrandStatus.IN_PROGRESS;
    } else {
      throw new BadRequestException(
        'Invalid status transition',
      );
    }

    const result = await this.prisma.errand.updateMany({
      where: {
        id: errandId,
        runnerId,
        status: currentStatus,
      },
      data: {
        status: dto.status,
      },
    });

    if (result.count === 0) {
      const errand = await this.prisma.errand.findUnique({
        where: { id: errandId },
      });

      if (!errand) {
        throw new NotFoundException('Errand not found');
      }

      if (errand.runnerId !== runnerId) {
        throw new ForbiddenException(
          'This errand is not assigned to you',
        );
      }

      throw new BadRequestException(
        `Cannot change status from ${errand.status} to ${dto.status}`,
      );
    }

    return this.prisma.errand.findUnique({
      where: { id: errandId },
    });
  }
}
