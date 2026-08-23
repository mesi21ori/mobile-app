import { BadRequestException, Injectable } from '@nestjs/common';
import { FinanceType, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { FinanceDto } from './dto';

@Injectable()
export class FinanceService {
  constructor(private prisma: PrismaService) {}

  private async openingMeta() {
    const [balance, locked] = await Promise.all([
      this.prisma.setting.findUnique({ where: { key: 'opening_balance' } }),
      this.prisma.setting.findUnique({ where: { key: 'opening_balance_locked' } }),
    ]);
    return {
      openingBalance: Number(balance?.value || 0),
      openingBalanceLocked: locked?.value === 'true',
    };
  }

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
    const opening = eventId ? { openingBalance: 0, openingBalanceLocked: true } : await this.openingMeta();
    return {
      income,
      expense,
      ...opening,
      net: (opening.openingBalance || 0) + income - expense,
    };
  }

  async setOpeningBalance(amount: number) {
    const { openingBalanceLocked } = await this.openingMeta();
    if (openingBalanceLocked) {
      throw new BadRequestException('የመጀመሪያ ቀሪ ሒሳብ ቀድሞ ተቀምጧል · መቀየር አይችልም');
    }
    if (amount < 0) throw new BadRequestException('ትክክለኛ መጠን ያስገቡ');
    await this.prisma.setting.upsert({
      where: { key: 'opening_balance' },
      create: { key: 'opening_balance', value: String(amount) },
      update: { value: String(amount) },
    });
    await this.prisma.setting.upsert({
      where: { key: 'opening_balance_locked' },
      create: { key: 'opening_balance_locked', value: 'true' },
      update: { value: 'true' },
    });
    return this.summary();
  }
}
