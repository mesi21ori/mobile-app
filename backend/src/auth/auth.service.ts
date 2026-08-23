import { BadRequestException, Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../prisma/prisma.service';
import { LoginDto } from './dto';
import { UpdateProfileDto } from './profile.dto';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwt: JwtService,
  ) {}

  async login(dto: LoginDto) {
    const user = await this.prisma.user.findUnique({
      where: { username: dto.username.trim() },
    });
    if (!user || !user.isActive) {
      throw new UnauthorizedException('የተጠቃሚ ስም ወይም የይለፍ ቃል ትክክል አይደለም');
    }
    const ok = await bcrypt.compare(dto.password, user.passwordHash);
    if (!ok) {
      throw new UnauthorizedException('የተጠቃሚ ስም ወይም የይለፍ ቃል ትክክል አይደለም');
    }
    const token = await this.jwt.signAsync({
      sub: user.id,
      role: user.role,
    });
    return {
      token,
      user: {
        id: user.id,
        fullName: user.fullName,
        username: user.username,
        role: user.role,
        memberId: user.memberId,
        groupId: user.groupId,
      },
    };
  }

  async me(userId: number) {
    return this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        fullName: true,
        username: true,
        role: true,
        memberId: true,
        groupId: true,
        isActive: true,
      },
    });
  }

  async updateProfile(userId: number, dto: UpdateProfileDto) {
    const data: { fullName?: string; passwordHash?: string } = {};
    if (dto.fullName?.trim()) data.fullName = dto.fullName.trim();
    if (dto.password) data.passwordHash = await bcrypt.hash(dto.password, 10);
    if (!data.fullName && !data.passwordHash) {
      throw new BadRequestException('ምንም ለማስተካከል አልተላከም');
    }
    return this.prisma.user.update({
      where: { id: userId },
      data,
      select: {
        id: true,
        fullName: true,
        username: true,
        role: true,
        memberId: true,
        groupId: true,
        isActive: true,
      },
    });
  }
}
