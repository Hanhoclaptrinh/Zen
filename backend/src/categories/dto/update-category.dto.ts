import { IsEnum, IsOptional, IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class UpdateCategoryDto {
  @ApiProperty({ example: 'Ăn uống', required: false })
  @IsOptional()
  @IsString()
  name: string;

  @ApiProperty({
    enum: ['income', 'expense'],
    example: 'expense',
    required: false,
  })
  @IsOptional()
  @IsEnum(['income', 'expense'])
  type: 'income' | 'expense';
}
