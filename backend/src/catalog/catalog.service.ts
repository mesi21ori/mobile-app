import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  AddGroupMembersDto,
  DepartmentDto,
  EventDto,
  GroupDto,
  MemberDto,
  UpdateDepartmentDto,
  UpdateEventDto,
  UpdateMemberDto,
  UpdateVestmentDto,
  VestmentDto,
} from './dto';

@Injectable()
export class CatalogService {
  constructor(private prisma: PrismaService) {}

  departments() {
    return this.prisma.department.findMany({ orderBy: { name: 'asc' } });
  }

  createDepartment(dto: DepartmentDto) {
    return this.prisma.department.create({ data: { name: dto.name.trim(), head: dto.head?.trim() || null } });
  }

  async updateDepartment(id: number, dto: UpdateDepartmentDto) {
    const dept = await this.prisma.department.findUnique({ where: { id } });
    if (!dept) throw new BadRequestException('ክፍሉ አልተገኘም');
    return this.prisma.department.update({
      where: { id },
      data: {
        ...(dto.name != null && dto.name.trim() ? { name: dto.name.trim() } : {}),
        ...(dto.head !== undefined ? { head: dto.head?.trim() || null } : {}),
      },
    });
  }

  async deleteDepartment(id: number) {
    const [members, loans, audits] = await Promise.all([
      this.prisma.member.count({ where: { departmentId: id } }),
      this.prisma.assetLoan.count({ where: { departmentId: id } }),
      this.prisma.assetAudit.count({ where: { departmentId: id } }),
    ]);
    if (members || loans || audits) {
      throw new BadRequestException('ይህ ክፍል ተጠቅሟል · ሊወገድ አይችልም');
    }
    await this.prisma.asset.updateMany({ where: { departmentId: id }, data: { departmentId: null } });
    return this.prisma.department.delete({ where: { id } });
  }

  members() {
    return this.prisma.member.findMany({
      include: { department: true },
      orderBy: { fullName: 'asc' },
    });
  }

  async createMember(dto: MemberDto) {
    const member = await this.prisma.member.create({
      data: {
        fullName: dto.fullName,
        phoneNumber: dto.phoneNumber,
        departmentId: dto.departmentId,
      },
      include: { department: true, groupMembers: true },
    });
    if (dto.groupId) {
      await this.prisma.groupMember.createMany({
        data: [{ groupId: dto.groupId, memberId: member.id }],
        skipDuplicates: true,
      });
    }
    return this.prisma.member.findUnique({
      where: { id: member.id },
      include: { department: true, groupMembers: { include: { group: true } } },
    });
  }

  async updateMember(id: number, dto: UpdateMemberDto) {
    const member = await this.prisma.member.findUnique({ where: { id } });
    if (!member) throw new BadRequestException('አባሉ አልተገኘም');
    return this.prisma.member.update({
      where: { id },
      data: {
        ...(dto.fullName != null && dto.fullName.trim() ? { fullName: dto.fullName.trim() } : {}),
        ...(dto.phoneNumber !== undefined ? { phoneNumber: dto.phoneNumber?.trim() || null } : {}),
      },
      include: { department: true, groupMembers: { include: { group: true } } },
    });
  }

  async deleteMember(id: number) {
    const [vestments, assets, user] = await Promise.all([
      this.prisma.vestmentLoan.count({ where: { memberId: id } }),
      this.prisma.assetLoan.count({ where: { memberId: id } }),
      this.prisma.user.count({ where: { memberId: id } }),
    ]);
    if (vestments || assets || user) {
      throw new BadRequestException('ይህ አባል ታሪክ አለው · ሊወገድ አይችልም');
    }
    await this.prisma.groupMember.deleteMany({ where: { memberId: id } });
    return this.prisma.member.delete({ where: { id } });
  }

  vestments() {
    return this.prisma.vestment.findMany({ orderBy: { name: 'asc' } });
  }

  async createVestment(dto: VestmentDto) {
    if (dto.totalQuantity < 0) throw new BadRequestException('ብዛት ትክክል አይደለም');
    return this.prisma.vestment.create({
      data: {
        name: dto.name.trim(),
        totalQuantity: dto.totalQuantity,
        availableQuantity: dto.totalQuantity,
      },
    });
  }

  async updateVestment(id: number, dto: UpdateVestmentDto) {
    const vestment = await this.prisma.vestment.findUnique({ where: { id } });
    if (!vestment) throw new BadRequestException('ልብሱ አልተገኘም');
    const data: { name?: string; totalQuantity?: number; availableQuantity?: number } = {};
    if (dto.name != null && dto.name.trim()) data.name = dto.name.trim();
    if (dto.totalQuantity != null) {
      const qty = Number(dto.totalQuantity);
      const delta = qty - vestment.totalQuantity;
      const nextAvailable = vestment.availableQuantity + delta;
      if (nextAvailable < 0) {
        throw new BadRequestException(`የወጣ ${vestment.issuedQuantity} ስላለ፣ ጠቅላላ ብዛት ከዚያ መቀነስ አይችልም`);
      }
      data.totalQuantity = qty;
      data.availableQuantity = nextAvailable;
    }
    return this.prisma.vestment.update({ where: { id }, data });
  }

  async deleteVestment(id: number) {
    const loans = await this.prisma.vestmentLoan.count({ where: { vestmentId: id } });
    if (loans) throw new BadRequestException('ይህ ልብስ ተሰጥቷል · ሊወገድ አይችልም');
    return this.prisma.vestment.delete({ where: { id } });
  }

  events() {
    return this.prisma.event.findMany({
      orderBy: { issueDate: 'desc' },
    });
  }

  createEvent(dto: EventDto) {
    return this.prisma.event.create({
      data: {
        name: dto.name.trim(),
        issueDate: new Date(dto.issueDate),
        dueDate: new Date(dto.dueDate),
      },
    });
  }

  async updateEvent(id: number, dto: UpdateEventDto) {
    const event = await this.prisma.event.findUnique({ where: { id } });
    if (!event) throw new BadRequestException('በዓሉ አልተገኘም');
    return this.prisma.event.update({
      where: { id },
      data: {
        ...(dto.name != null && dto.name.trim() ? { name: dto.name.trim() } : {}),
        ...(dto.issueDate ? { issueDate: new Date(dto.issueDate) } : {}),
        ...(dto.dueDate ? { dueDate: new Date(dto.dueDate) } : {}),
      },
    });
  }

  async deleteEvent(id: number) {
    const [loans, finance] = await Promise.all([
      this.prisma.vestmentLoan.count({ where: { eventId: id } }),
      this.prisma.finance.count({ where: { eventId: id } }),
    ]);
    if (loans || finance) throw new BadRequestException('ይህ በዓል ታሪክ አለው · ሊወገድ አይችልም');
    return this.prisma.event.delete({ where: { id } });
  }

  groups() {
    return this.prisma.group.findMany({
      include: {
        members: { include: { member: true } },
      },
      orderBy: { name: 'asc' },
    });
  }

  createGroup(dto: GroupDto) {
    return this.prisma.group.create({
      data: { name: dto.name.trim() },
      include: { members: { include: { member: true } } },
    });
  }

  async updateGroup(id: number, dto: GroupDto) {
    const group = await this.prisma.group.findUnique({ where: { id } });
    if (!group) throw new BadRequestException('ምድቡ አልተገኘም');
    return this.prisma.group.update({
      where: { id },
      data: { name: dto.name.trim() },
      include: { members: { include: { member: true } } },
    });
  }

  async deleteGroup(id: number) {
    const loans = await this.prisma.vestmentLoan.count({ where: { groupId: id } });
    if (loans) throw new BadRequestException('ይህ ምድብ ልብስ ወጥቶበታል · ሊወገድ አይችልም');
    await this.prisma.groupMember.deleteMany({ where: { groupId: id } });
    return this.prisma.group.delete({ where: { id } });
  }

  async addGroupMembers(dto: AddGroupMembersDto) {
    await this.prisma.groupMember.createMany({
      data: dto.memberIds.map((memberId) => ({ groupId: dto.groupId, memberId })),
      skipDuplicates: true,
    });
    return this.prisma.group.findUnique({
      where: { id: dto.groupId },
      include: { members: { include: { member: true } } },
    });
  }

  settings() {
    return this.prisma.setting.findMany();
  }

  async setSetting(key: string, value: string) {
    return this.prisma.setting.upsert({
      where: { key },
      create: { key, value },
      update: { value },
    });
  }

  async dashboard() {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const [
      members,
      classes,
      departments,
      events,
      clothesOut,
      dirtyClothes,
      overdueClothes,
      returnableAssets,
      consumableAssets,
      openReturnableLoans,
      audits,
      vestmentStock,
      finance,
    ] = await Promise.all([
      this.prisma.member.count(),
      this.prisma.group.count(),
      this.prisma.department.count(),
      this.prisma.event.count(),
      this.prisma.vestmentLoan.count({ where: { isReturned: false } }),
      this.prisma.vestmentLoan.count({ where: { isReturned: false, isDirty: true, isWashed: false } }),
      this.prisma.vestmentLoan.count({ where: { isReturned: false, dueDate: { lt: today } } }),
      this.prisma.asset.count({ where: { type: 'RETURNABLE' } }),
      this.prisma.asset.count({ where: { type: 'CONSUMABLE' } }),
      this.prisma.assetLoan.count({ where: { isReturned: false, asset: { type: 'RETURNABLE' } } }),
      this.prisma.assetAudit.count(),
      this.prisma.vestment.aggregate({
        _sum: { totalQuantity: true, availableQuantity: true, issuedQuantity: true },
      }),
      this.prisma.finance.groupBy({ by: ['type'], _sum: { amount: true } }),
    ]);
    const income = Number(finance.find((g) => g.type === 'INCOME')?._sum.amount || 0);
    const expense = Number(finance.find((g) => g.type === 'EXPENSE')?._sum.amount || 0);
    return {
      members,
      classes,
      departments,
      events,
      clothesOut,
      dirtyClothes,
      overdueClothes,
      returnableAssets,
      consumableAssets,
      openReturnableLoans,
      audits,
      vestmentTotal: vestmentStock._sum.totalQuantity || 0,
      vestmentAvailable: vestmentStock._sum.availableQuantity || 0,
      vestmentIssued: vestmentStock._sum.issuedQuantity || 0,
      income,
      expense,
      net: income - expense,
    };
  }
}
