import { Injectable } from '@nestjs/common';
import { FinanceType, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { FinanceDto } from './dto';

@Injectable()
export class FinanceService {
  constructor(private prisma: PrismaService) {}

  list(eventId?: number) {
    return this.prisma.finance.findMany({
      where: eventId ? { eventId } : undefined,
      include: { event: true, createdBy: { select: { id: true, fullName: true } } },
      orderBy: { createdAt: 'desc' },
    });
  }

  create(dto: FinanceDto, userId: number) {
    return this.prisma.finance.create({
      data: {
        eventId: dto.eventId || null,
        type: dto.type,
        reason: dto.reason,
        amount: new Prisma.Decimal(dto.amount),
        createdById: userId,
      },
      include: { event: true },
    });
  }

  async summary(eventId?: number) {
    const where = eventId ? { eventId } : {};
    const groups = await this.prisma.finance.groupBy({
      by: ['type'],
      where,
      _sum: { amount: true },
    });
    const income = Number(groups.find((g) => g.type === FinanceType.INCOME)?._sum.amount || 0);
    const expense = Number(groups.find((g) => g.type === FinanceType.EXPENSE)?._sum.amount || 0);
    return {
      income,
      expense,
      net: income - expense,
    };
  }
}
