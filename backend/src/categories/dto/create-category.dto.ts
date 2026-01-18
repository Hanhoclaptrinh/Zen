import { IsEnum, IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateCategoryDto {
  @ApiProperty({ example: 'Ăn uống' })
  @IsString()
  name: string;

  @ApiProperty({ enum: ['income', 'expense'], example: 'expense' })
  @IsEnum(['income', 'expense'])
  type: 'income' | 'expense';
}
