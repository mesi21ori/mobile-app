import { BadRequestException, Injectable } from '@nestjs/common';
import { Role } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../prisma/prisma.service';
import { CreateUserDto, UpdateUserDto } from './dto';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  list() {
    return this.prisma.user.findMany({
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        fullName: true,
        username: true,
        role: true,
        memberId: true,
        isActive: true,
        createdAt: true,
      },
    });
  }

  async create(dto: CreateUserDto, actorRole: Role) {
    if (actorRole !== Role.SUPER_ADMIN) {
      throw new BadRequestException('ተጠቃሚ መፍጠር የዋና አስተዳዳሪ ብቻ ነው');
    }
    const exists = await this.prisma.user.findUnique({
      where: { username: dto.username.trim() },
    });
    if (exists) throw new BadRequestException('የተጠቃሚ ስም ተይዟል');
    const passwordHash = await bcrypt.hash(dto.password, 10);
    return this.prisma.user.create({
      data: {
        fullName: dto.fullName,
        username: dto.username.trim(),
        passwordHash,
        role: dto.role,
        memberId: dto.memberId,
      },
      select: {
        id: true,
        fullName: true,
        username: true,
        role: true,
        memberId: true,
        isActive: true,
      },
    });
  }

  async update(id: number, dto: UpdateUserDto, actorRole: Role) {
    if (actorRole !== Role.SUPER_ADMIN) {
      throw new BadRequestException('ተጠቃሚ ማስተካከል የዋና አስተዳዳሪ ብቻ ነው');
    }
    const data: any = { ...dto };
    delete data.password;
    if (dto.password) {
      data.passwordHash = await bcrypt.hash(dto.password, 10);
    }
    return this.prisma.user.update({
      where: { id },
      data,
      select: {
        id: true,
        fullName: true,
        username: true,
        role: true,
        isActive: true,
      },
    });
  }
}
