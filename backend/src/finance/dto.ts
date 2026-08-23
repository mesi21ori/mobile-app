import { FinanceType } from '@prisma/client';
import { IsEnum, IsNumber, IsOptional, IsString } from 'class-validator';

export class FinanceDto {
  @IsOptional()
  eventId?: number | null;

  @IsEnum(FinanceType)
  type: FinanceType;

  @IsString()
  reason: string;

  @IsNumber()
  amount: number;
}

export class OpeningBalanceDto {
  @IsNumber()
  amount: number;
}
