import { BadRequestException, Injectable } from '@nestjs/common';
import { AssetType, AuditPeriod, AuditStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateAuditDto } from './dto';

function gregorianToJdn(year: number, month: number, day: number) {
  const a = Math.floor((14 - month) / 12);
  const y = year + 4800 - a;
  const m = month + 12 * a - 3;
  return day + Math.floor((153 * m + 2) / 5) + 365 * y + Math.floor(y / 4) - Math.floor(y / 100) + Math.floor(y / 400) - 32045;
}

function ethiopiaYmd(d: Date) {
  const utc = new Date(d.getTime() + 3 * 60 * 60 * 1000);
  return { y: utc.getUTCFullYear(), m: utc.getUTCMonth() + 1, day: utc.getUTCDate() };
}

function ethiopianYear(d: Date) {
  const { y, m, day } = ethiopiaYmd(d);
  const jdn = gregorianToJdn(y, m, day);
  const r = (((jdn - 1723856) % 1461) + 1461) % 1461;
  return 4 * Math.floor((jdn - 1723856) / 1461) + Math.floor(r / 365) - Math.floor(r / 1460);
}

@Injectable()
export class AuditsService {
  constructor(private prisma: PrismaService) {}

  private maxPerYear(period: AuditPeriod) {
    return period === AuditPeriod.THREE_MONTHS ? 4 : 2;
  }

  list() {
    return this.prisma.assetAudit.findMany({
      include: {
        department: true,
        auditedBy: { select: { id: true, fullName: true } },
        approvedBy: { select: { id: true, fullName: true } },
        details: { include: { asset: true } },
      },
      orderBy: { id: 'desc' },
    });
  }

  private async yearCount(departmentId: number, period: AuditPeriod) {
    const year = ethiopianYear(new Date());
    const rows = await this.prisma.assetAudit.findMany({
      where: { departmentId, period },
      select: { auditDate: true },
    });
    return rows.filter((row) => ethiopianYear(new Date(row.auditDate)) === year).length;
  }

  private async maxLoanId(departmentId: number) {
    const agg = await this.prisma.assetLoan.aggregate({
      where: { departmentId, asset: { type: AssetType.CONSUMABLE } },
      _max: { id: true },
    });
    return agg._max.id ?? 0;
  }

  async preview(departmentId: number, period: AuditPeriod = AuditPeriod.SIX_MONTHS) {
    if (!Number.isInteger(departmentId)) throw new BadRequestException('ክፍል ይምረጡ');

    const maxAudits = this.maxPerYear(period);
    const auditsThisYear = await this.yearCount(departmentId, period);

    const audits = await this.prisma.assetAudit.findMany({
      where: { departmentId },
      include: { details: { include: { asset: true } } },
      orderBy: { id: 'desc' },
    });
    const last = audits[0] ?? null;
    const firstAudit = !last;

    const lastByAsset = new Map<
      number,
      { asset: { id: number; name: string; type: AssetType }; opening: number; cutoff: number | null }
    >();
    for (const audit of audits) {
      for (const detail of audit.details) {
        if (!detail.asset || detail.asset.type === AssetType.RETURNABLE) continue;
        if (lastByAsset.has(detail.assetId)) continue;
        lastByAsset.set(detail.assetId, {
          asset: detail.asset,
          opening: Number(detail.physicalQuantity || 0),
          cutoff: audit.lastCountedLoanId,
        });
      }
    }

    const loans = await this.prisma.assetLoan.findMany({
      where: { departmentId, asset: { type: AssetType.CONSUMABLE } },
      include: { asset: true },
      orderBy: { id: 'asc' },
    });

    const rows = new Map<
      number,
      {
        asset: { id: number; name: string; type: AssetType };
        opening: number;
        newTaken: number;
        fromLastAudit: boolean;
      }
    >();

    const add = (asset: { id: number; name: string; type: AssetType }) => {
      if (!rows.has(asset.id)) {
        rows.set(asset.id, { asset, opening: 0, newTaken: 0, fromLastAudit: false });
      }
      return rows.get(asset.id)!;
    };

    for (const prev of lastByAsset.values()) {
      const row = add(prev.asset);
      row.opening = prev.opening;
      row.fromLastAudit = true;
    }

    for (const loan of loans) {
      const row = add(loan.asset);
      const prev = lastByAsset.get(loan.assetId);
      if (!prev) {
        row.newTaken += loan.quantity;
        continue;
      }
      if (prev.cutoff != null && loan.id > prev.cutoff) {
        row.newTaken += loan.quantity;
      }
    }

    const lines = [...rows.values()]
      .map((row) => {
        const taken = row.opening + row.newTaken;
        return {
          assetId: row.asset.id,
          name: row.asset.name,
          type: row.asset.type,
          opening: row.opening,
          newTaken: row.newTaken,
          taken,
          systemQuantity: taken,
          fromLastAudit: row.fromLastAudit,
        };
      })
      .filter((row) => row.fromLastAudit || row.newTaken > 0 || row.taken > 0);

    return {
      departmentId,
      period,
      firstAudit,
      maxAudits,
      auditsThisYear,
      remainingAudits: Math.max(0, maxAudits - auditsThisYear),
      lastAudit: last ? { id: last.id, auditDate: last.auditDate, period: last.period } : null,
      lines,
    };
  }

  async create(dto: CreateAuditDto, userId: number) {
    const departmentId = Number(dto.departmentId);
    const maxAudits = this.maxPerYear(dto.period);
    const used = await this.yearCount(departmentId, dto.period);
    if (used >= maxAudits) {
      const label = dto.period === AuditPeriod.THREE_MONTHS ? '3 ወር' : '6 ወር';
      throw new BadRequestException(
        `በዚህ ዓመት የ${label} ኦዲት ${maxAudits} ጊዜ ብቻ ነው። ተጨማሪ አይቻልም።`,
      );
    }

    const preview = await this.preview(departmentId, dto.period);
    const byId = new Map(preview.lines.map((row) => [row.assetId, row]));
    if (dto.lines.length === 0) throw new BadRequestException('ለኦዲት የሚቆጠር ንብረት የለም');

    const lastCountedLoanId = await this.maxLoanId(departmentId);

    return this.prisma.assetAudit.create({
      data: {
        departmentId,
        auditedById: userId,
        period: dto.period,
        status: AuditStatus.SUBMITTED,
        lastCountedLoanId,
        details: {
          create: dto.lines.map((line) => {
            const row = byId.get(Number(line.assetId));
            const systemQuantity = row?.systemQuantity ?? 0;
            const physicalQuantity = Number(line.physicalQuantity);
            return {
              assetId: Number(line.assetId),
              systemQuantity,
              physicalQuantity,
              discrepancy: physicalQuantity - systemQuantity,
              remarks: line.remarks,
            };
          }),
        },
      },
      include: { department: true, details: { include: { asset: true } } },
    });
  }

  async approve(id: number, userId: number) {
    const audit = await this.prisma.assetAudit.findUnique({ where: { id } });
    if (!audit) throw new BadRequestException('ኦዲቱ አልተገኘም');
    if (audit.status === AuditStatus.APPROVED) {
      throw new BadRequestException('ኦዲቱ አስቀድሞ ጸድቋል');
    }

    return this.prisma.assetAudit.update({
      where: { id },
      data: {
        status: AuditStatus.APPROVED,
        approvedById: userId,
      },
      include: {
        department: true,
        details: { include: { asset: true } },
        approvedBy: { select: { fullName: true } },
      },
    });
  }
}
