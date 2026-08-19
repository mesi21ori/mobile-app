import { Transform, Type } from 'class-transformer';
import { IsArray, IsBoolean, IsInt, IsOptional } from 'class-validator';

const toIntArray = ({ value }: { value: unknown }) =>
  Array.isArray(value) ? value.map((v) => Number(v)) : value;

export class IssueVestmentDto {
  @Type(() => Number)
  @IsInt()
  eventId: number;

  @Type(() => Number)
  @IsInt()
  groupId: number;

  @Type(() => Number)
  @IsInt()
  memberId: number;

  @Transform(toIntArray)
  @IsArray()
  @IsInt({ each: true })
  vestmentIds: number[];
}

export class BulkIssueDto {
  @Type(() => Number)
  @IsInt()
  eventId: number;

  @Type(() => Number)
  @IsInt()
  groupId: number;

  @Transform(toIntArray)
  @IsArray()
  @IsInt({ each: true })
  vestmentIds: number[];
}

export class ReturnVestmentDto {
  @Type(() => Number)
  @IsInt()
  loanId: number;

  @IsBoolean()
  isReturned: boolean;

  @IsOptional()
  @IsBoolean()
  isDirty?: boolean;
}
