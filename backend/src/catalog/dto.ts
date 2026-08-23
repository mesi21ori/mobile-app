import { IsArray, IsInt, IsOptional, IsString, Min } from 'class-validator';
import { Type } from 'class-transformer';

export class DepartmentDto {
  @IsString()
  name: string;

  @IsOptional()
  @IsString()
  head?: string;
}

export class UpdateDepartmentDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsString()
  head?: string;
}

export class MemberDto {
  @IsString()
  fullName: string;

  @IsOptional()
  @IsString()
  phoneNumber?: string;

  @IsOptional()
  @IsInt()
  departmentId?: number;

  @IsOptional()
  @IsInt()
  groupId?: number;
}

export class UpdateMemberDto {
  @IsOptional()
  @IsString()
  fullName?: string;

  @IsOptional()
  @IsString()
  phoneNumber?: string;
}

export class VestmentDto {
  @IsString()
  name: string;

  @Type(() => Number)
  @IsInt()
  @Min(0)
  totalQuantity: number;
}

export class UpdateVestmentDto {
  @IsOptional()
  @IsString()
  name?: string;

  @Type(() => Number)
  @IsOptional()
  @IsInt()
  @Min(0)
  totalQuantity?: number;
}

export class EventDto {
  @IsString()
  name: string;

  @IsString()
  issueDate: string;

  @IsString()
  dueDate: string;
}

export class UpdateEventDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsString()
  issueDate?: string;

  @IsOptional()
  @IsString()
  dueDate?: string;
}

export class GroupDto {
  @IsString()
  name: string;
}

export class AddGroupMembersDto {
  @IsInt()
  groupId: number;

  @IsArray()
  @IsInt({ each: true })
  memberIds: number[];
}

export class SetEventParticipantsDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  groupId?: number;

  @IsArray()
  @IsInt({ each: true })
  memberIds: number[];
}
