import { BadRequestException, Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { BulkIssueDto, IssueVestmentDto, ReturnVestmentDto } from './dto';

@Injectable()
export class VestmentsService {
  constructor(private prisma: PrismaService) {}

  private daysBetween(a: Date, b: Date) {
    const ms = 1000 * 60 * 60 * 24;
    return Math.floor((a.getTime() - b.getTime()) / ms);
  }

  private async dailyRate() {
    const row = await this.prisma.setting.findUnique({
      where: { key: 'daily_penalty_rate' },
    });
    return Number(row?.value || 10);
  }

  loans(query: { eventId?: number; groupId?: number; memberId?: number; dirty?: boolean; unreturned?: boolean }) {
    return this.prisma.vestmentLoan.findMany({
      where: {
        eventId: query.eventId,
        groupId: query.groupId,
        memberId: query.memberId,
        ...(query.dirty ? { isDirty: true, isWashed: false, isReturned: false } : {}),
        ...(query.unreturned && !query.dirty ? { isReturned: false } : {}),
      },
      include: {
        vestment: true,
        member: true,
        group: true,
        event: true,
      },
      orderBy: { id: 'desc' },
    });
  }

  private async assertParticipant(eventId: number, groupId: number, memberId: number) {
    const row = await this.prisma.eventParticipant.findUnique({
      where: { eventId_groupId_memberId: { eventId, groupId, memberId } },
    });
    if (!row) throw new BadRequestException('ተማሪው ለዚህ በዓል አልተመዘገበም · መደብ አስተዳዳሪው ይመድቡ');
  }

  async issue(dto: IssueVestmentDto) {
    const eventId = Number(dto.eventId);
    const groupId = Number(dto.groupId);
    const memberId = Number(dto.memberId);
    const vestmentIds = [...new Set((dto.vestmentIds || []).map((id) => Number(id)))].filter((id) =>
      Number.isInteger(id),
    );
    if (![eventId, groupId, memberId].every((id) => Number.isInteger(id))) {
      throw new BadRequestException('ትክክለኛ መረጃ ያስገቡ');
    }
    if (vestmentIds.length === 0) throw new BadRequestException('ልብስ ይምረጡ');

    const event = await this.prisma.event.findUnique({ where: { id: eventId } });
    if (!event) throw new BadRequestException('በዓሉ አልተገኘም');
    await this.assertParticipant(eventId, groupId, memberId);

    const created: any[] = [];
    for (const vestmentId of vestmentIds) {
      const vestment = await this.prisma.vestment.findUnique({ where: { id: vestmentId } });
      if (!vestment || vestment.availableQuantity < 1) {
        throw new BadRequestException(`${vestment?.name || 'ልብስ'} በቂ አይደለም`);
      }
      await this.prisma.vestment.update({
        where: { id: vestmentId },
        data: {
          availableQuantity: { decrement: 1 },
          issuedQuantity: { increment: 1 },
        },
      });
      created.push(
        await this.prisma.vestmentLoan.create({
          data: {
            eventId,
            groupId,
            memberId,
            vestmentId,
            issueDate: event.issueDate,
            dueDate: event.dueDate,
          },
          include: { vestment: true, member: true },
        }),
      );
    }
    return created;
  }

  async bulkIssue(dto: BulkIssueDto) {
    const groupId = Number(dto.groupId);
    const eventId = Number(dto.eventId);
    const vestmentIds = [...new Set((dto.vestmentIds || []).map((id) => Number(id)))].filter((id) =>
      Number.isInteger(id),
    );
    if (![eventId, groupId].every((id) => Number.isInteger(id)) || vestmentIds.length === 0) {
      throw new BadRequestException('ትክክለኛ መረጃ ያስገቡ');
    }
    const participants = await this.prisma.eventParticipant.findMany({
      where: { eventId, groupId },
    });
    if (participants.length === 0) {
      throw new BadRequestException('ለዚህ በዓል በመደቡ ውስጥ የተመዘገቡ ተማሪዎች የለም');
    }
    const results: any[] = [];
    for (const p of participants) {
      results.push(
        ...(await this.issue({
          eventId,
          groupId,
          memberId: p.memberId,
          vestmentIds,
        })),
      );
    }
    return results;
  }

  async returnLoan(dto: ReturnVestmentDto) {
    const loan = await this.prisma.vestmentLoan.findUnique({
      where: { id: dto.loanId },
      include: { vestment: true, member: true, event: true },
    });
    if (!loan) throw new BadRequestException('መዝገቡ አልተገኘም');

    const dirty = !!dto.isDirty;
    const wantReturn = !!dto.isReturned;

    if (dirty) {
      if (loan.isReturned) {
        throw new BadRequestException('የተመለሰ ልብስ እንደ ቆሻሻ ሊቆይ አይችልም');
      }
      return this.prisma.vestmentLoan.update({
        where: { id: loan.id },
        data: { isDirty: true, isReturned: false, isWashed: false, returnedDate: null },
        include: { vestment: true, member: true, event: true },
      });
    }

    if (wantReturn) {
      if (loan.isDirty && !loan.isWashed) {
        throw new BadRequestException('ቆሸሸ ልብስ መጀመሪያ ይታጠብ፤ ከዚያ በኋላ ይመለሳል');
      }
      if (loan.isReturned) {
        return loan;
      }
      const rate = await this.dailyRate();
      const today = new Date();
      const lateDays = Math.max(0, this.daysBetween(today, new Date(loan.dueDate)));
      const penalty = lateDays * rate;
      await this.prisma.vestment.update({
        where: { id: loan.vestmentId },
        data: {
          issuedQuantity: { decrement: 1 },
          availableQuantity: { increment: 1 },
        },
      });
      return this.prisma.vestmentLoan.update({
        where: { id: loan.id },
        data: {
          isReturned: true,
          isDirty: false,
          returnedDate: today,
          penaltyAmount: new Prisma.Decimal(penalty),
        },
        include: { vestment: true, member: true, event: true },
      });
    }

    return this.prisma.vestmentLoan.update({
      where: { id: loan.id },
      data: { isDirty: false },
      include: { vestment: true, member: true, event: true },
    });
  }

  async markWashed(loanId: number) {
    const loan = await this.prisma.vestmentLoan.findUnique({ where: { id: loanId } });
    if (!loan || loan.isReturned || !loan.isDirty) {
      throw new BadRequestException('ይህ ልብስ ለማጠብ ዝርዝር ውስጥ የለም');
    }
    return this.prisma.vestmentLoan.update({
      where: { id: loanId },
      data: { isDirty: false, isWashed: true },
      include: { vestment: true, member: true, event: true },
    });
  }
}
