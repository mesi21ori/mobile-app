import { IsBoolean, IsIn, IsInt, IsOptional, IsString, MinLength } from 'class-validator';
import { Role } from '@prisma/client';

const ROLES = ['SUPER_ADMIN', 'ADMIN', 'CLASS_LEADER', 'USER'] as const;

export class CreateUserDto {
  @IsString()
  fullName: string;

  @IsString()
  username: string;

  @IsString()
  @MinLength(6)
  password: string;

  @IsIn(ROLES)
  role: Role;

  @IsOptional()
  @IsInt()
  memberId?: number;

  @IsOptional()
  @IsInt()
  groupId?: number;
}

export class UpdateUserDto {
  @IsOptional()
  @IsString()
  fullName?: string;

  @IsOptional()
  @IsString()
  password?: string;

  @IsOptional()
  @IsIn(ROLES)
  role?: Role;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @IsOptional()
  @IsInt()
  groupId?: number;
}
