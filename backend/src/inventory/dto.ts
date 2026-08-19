import { Type } from 'class-transformer';
import { AssetType } from '@prisma/client';
import { ArrayMinSize, IsArray, IsEnum, IsInt, IsOptional, IsString, Min, ValidateNested } from 'class-validator';

export class AssetDto {
  @IsString()
  name: string;

  @IsEnum(AssetType)
  type: AssetType;

  @Type(() => Number)
  @IsInt()
  @Min(0)
  totalQuantity: number;
}

export class UpdateAssetDto {
  @IsOptional()
  @IsString()
  name?: string;

  @Type(() => Number)
  @IsOptional()
  @IsInt()
  @Min(0)
  totalQuantity?: number;
}

export class CheckoutDto {
  @Type(() => Number)
  @IsInt()
  assetId: number;

  @Type(() => Number)
  @IsInt()
  @Min(1)
  quantity: number;

  @Type(() => Number)
  @IsOptional()
  @IsInt()
  departmentId?: number;

  @Type(() => Number)
  @IsOptional()
  @IsInt()
  memberId?: number;
}

export class CheckoutManyDto {
  @Type(() => Number)
  @IsOptional()
  @IsInt()
  departmentId?: number;

  @Type(() => Number)
  @IsOptional()
  @IsInt()
  memberId?: number;

  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => CheckoutDto)
  lines: CheckoutDto[];
}

export class CheckinDto {
  @Type(() => Number)
  @IsInt()
  loanId: number;

  @Type(() => Number)
  @IsOptional()
  @IsInt()
  @Min(0)
  damagedQuantity?: number;

  @Type(() => Number)
  @IsOptional()
  @IsInt()
  @Min(0)
  lostQuantity?: number;
}
