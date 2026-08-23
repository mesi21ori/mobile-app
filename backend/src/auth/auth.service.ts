import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../prisma/prisma.service';
import { LoginDto } from './dto';

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
}
