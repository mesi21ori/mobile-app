import { AuditPeriod } from '@prisma/client';
import { IsArray, IsEnum, IsInt, IsOptional, IsString, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';

export class AuditLineDto {
  @Type(() => Number)
  @IsInt()
  assetId: number;

  @Type(() => Number)
  @IsInt()
  physicalQuantity: number;

  @IsOptional()
  @IsString()
  remarks?: string;
}

export class CreateAuditDto {
  @Type(() => Number)
  @IsInt()
  departmentId: number;

  @IsEnum(AuditPeriod)
  period: AuditPeriod;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => AuditLineDto)
  lines: AuditLineDto[];
}
