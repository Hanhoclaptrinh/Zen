import { IsEnum, IsOptional, IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export enum CategoryType {
    INCOME = 'income',
    EXPENSE = 'expense',
}

export class UpdateCategoryDto {
  @ApiProperty({ example: 'Ăn uống', required: false })
  @IsOptional()
  @IsString()
  name: string;

  @ApiProperty({
    enum: CategoryType,
    example: CategoryType.EXPENSE,
    required: false,
  })
  @IsOptional()
  @IsEnum(CategoryType)
  type: CategoryType;
}
