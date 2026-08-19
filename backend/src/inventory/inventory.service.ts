import { BadRequestException, Injectable } from '@nestjs/common';
import { AssetCondition, AssetType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { AssetDto, CheckinDto, CheckoutDto, CheckoutManyDto, UpdateAssetDto } from './dto';

@Injectable()
export class InventoryService {
  constructor(private prisma: PrismaService) {}

  assets(type?: AssetType) {
    return this.prisma.asset.findMany({
      where: type ? { type } : undefined,
      include: { department: true },
      orderBy: { name: 'asc' },
    });
  }

  createAsset(dto: AssetDto) {
    const qty = Number(dto.totalQuantity);
    if (!Number.isInteger(qty) || qty < 0) throw new BadRequestException('ብዛት ትክክል አይደለም');
    return this.prisma.asset.create({
      data: {
        name: dto.name.trim(),
        type: dto.type,
        departmentId: null,
        totalQuantity: qty,
        availableQuantity: qty,
      },
    });
  }

  async updateAsset(id: number, dto: UpdateAssetDto) {
    const asset = await this.prisma.asset.findUnique({ where: { id } });
    if (!asset) throw new BadRequestException('ንብረቱ አልተገኘም');

    const data: { name?: string; totalQuantity?: number; availableQuantity?: number } = {};
    if (dto.name != null && dto.name.trim()) data.name = dto.name.trim();
    if (dto.totalQuantity != null) {
      const qty = Number(dto.totalQuantity);
      if (!Number.isInteger(qty) || qty < 0) throw new BadRequestException('ብዛት ትክክል አይደለም');
      const delta = qty - asset.totalQuantity;
      const nextAvailable = asset.availableQuantity + delta;
      if (nextAvailable < 0) {
        throw new BadRequestException(`ያወጡ ${asset.issuedQuantity} ስላለ፣ ጠቅላላ ብዛት ከዚያ መቀነስ አይችልም`);
      }
      data.totalQuantity = qty;
      data.availableQuantity = nextAvailable;
    }
    return this.prisma.asset.update({ where: { id }, data });
  }

  loans(opts: { openOnly?: boolean; type?: AssetType; departmentId?: number } = {}) {
    return this.prisma.assetLoan.findMany({
      where: {
        ...(opts.openOnly ? { isReturned: false } : {}),
        ...(opts.departmentId ? { departmentId: opts.departmentId } : {}),
        ...(opts.type ? { asset: { type: opts.type } } : {}),
      },
      include: { asset: true, department: true, member: true },
      orderBy: { id: 'desc' },
    });
  }

  async checkout(dto: CheckoutDto) {
    const assetId = Number(dto.assetId);
    const quantity = Number(dto.quantity);
    const departmentId = dto.departmentId != null ? Number(dto.departmentId) : null;
    const memberId = dto.memberId != null ? Number(dto.memberId) : null;

    if (!Number.isInteger(assetId) || !Number.isInteger(quantity) || quantity < 1) {
      throw new BadRequestException('ትክክለኛ ብዛት ያስገቡ');
    }

    const asset = await this.prisma.asset.findUnique({ where: { id: assetId } });
    if (!asset) throw new BadRequestException('ንብረቱ አልተገኘም');
    if (asset.availableQuantity < quantity) {
      throw new BadRequestException('በቂ ንብረት የለም');
    }

    const consumable = asset.type === AssetType.CONSUMABLE;
    if (consumable && !departmentId) {
      throw new BadRequestException('አላቂ ንብረት ለክፍል ይወጣል · ክፍል ይምረጡ');
    }
    if (!consumable && !departmentId && !memberId) {
      throw new BadRequestException('ቋሚ ንብረት ለክፍል ወይም ለአባል ይወጣል');
    }

    await this.prisma.asset.update({
      where: { id: asset.id },
      data: {
        availableQuantity: { decrement: quantity },
        issuedQuantity: { increment: quantity },
      },
    });

    return this.prisma.assetLoan.create({
      data: {
        assetId,
        quantity,
        departmentId,
        memberId,
        isReturned: consumable,
        returnedDate: consumable ? new Date() : null,
      },
      include: { asset: true, department: true, member: true },
    });
  }

  async checkoutMany(dto: CheckoutManyDto) {
    const created: Awaited<ReturnType<InventoryService['checkout']>>[] = [];
    for (const line of dto.lines) {
      created.push(
        await this.checkout({
          assetId: line.assetId,
          quantity: line.quantity,
          departmentId: dto.departmentId ?? line.departmentId,
          memberId: dto.memberId ?? line.memberId,
        }),
      );
    }
    return created;
  }

  async checkin(dto: CheckinDto) {
    const loanId = Number(dto.loanId);
    const loan = await this.prisma.assetLoan.findUnique({
      where: { id: loanId },
      include: { asset: true },
    });
    if (!loan || loan.isReturned) throw new BadRequestException('መዝገቡ አልተገኘም ወይም ተመልሷል');
    if (loan.asset.type === AssetType.CONSUMABLE) {
      throw new BadRequestException('አላቂ ንብረት አይመለስም · ለኦዲት ብቻ ይቆጠራል');
    }

    const damaged = Math.max(0, Number(dto.damagedQuantity || 0));
    const lost = Math.max(0, Number(dto.lostQuantity || 0));
    const qty = loan.quantity;
    if (!Number.isInteger(damaged) || !Number.isInteger(lost) || damaged + lost > qty) {
      throw new BadRequestException(`የተበላሸ + የጎደለ ከ ${qty} መብለጥ አይችልም`);
    }
    const intact = qty - damaged - lost;

    await this.prisma.asset.update({
      where: { id: loan.assetId },
      data: {
        issuedQuantity: { decrement: qty },
        availableQuantity: { increment: intact },
        damagedQuantity: { increment: damaged },
        lostQuantity: { increment: lost },
      },
    });

    const condition =
      lost === qty
        ? AssetCondition.LOST
        : damaged === qty
          ? AssetCondition.DAMAGED
          : intact === qty
            ? AssetCondition.INTACT
            : damaged > 0
              ? AssetCondition.DAMAGED
              : lost > 0
                ? AssetCondition.LOST
                : AssetCondition.INTACT;

    return this.prisma.assetLoan.update({
      where: { id: loan.id },
      data: {
        isReturned: true,
        returnedDate: new Date(),
        condition,
        returnedIntact: intact,
        returnedDamaged: damaged,
        returnedLost: lost,
      },
      include: { asset: true, department: true, member: true },
    });
  }

  async deleteAsset(id: number) {
    const assetId = Number(id);
    const loans = await this.prisma.assetLoan.count({ where: { assetId } });
    if (loans > 0) {
      throw new BadRequestException('ይህ ንብረት ያወጡ መዝገብ አለው · መጀመሪያ ያወጡትን ያስወግዱ');
    }
    const audits = await this.prisma.auditDetail.count({ where: { assetId } });
    if (audits > 0) {
      throw new BadRequestException('በኦዲት ውስጥ ስለተጠቀሰ ሊወገድ አይችልም');
    }
    return this.prisma.asset.delete({ where: { id: assetId } });
  }

  async deleteLoan(id: number) {
    const loanId = Number(id);
    const loan = await this.prisma.assetLoan.findUnique({
      where: { id: loanId },
      include: { asset: true },
    });
    if (!loan) throw new BadRequestException('መዝገቡ አልተገኘም');
    if (loan.asset.type === AssetType.RETURNABLE && loan.isReturned) {
      throw new BadRequestException('የተመለሰ ቋሚ ንብረት አይወገድም');
    }

    await this.prisma.asset.update({
      where: { id: loan.assetId },
      data: {
        availableQuantity: { increment: loan.quantity },
        issuedQuantity: { decrement: loan.quantity },
      },
    });
    return this.prisma.assetLoan.delete({ where: { id: loanId } });
  }
}
