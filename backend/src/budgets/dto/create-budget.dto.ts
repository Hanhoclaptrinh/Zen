import { IsEnum, IsNumber, IsOptional, IsString } from "class-validator";
import { ApiProperty } from "@nestjs/swagger";

export class CreateBudgetDto {
    @ApiProperty({ example: 1000000, description: 'Hạn mức chi tiêu' })
    @IsNumber()
    amountLimit: number;

    @ApiProperty({ enum: ['monthly', 'weekly'], default: 'monthly' })
    @IsOptional()
    @IsEnum(['monthly', 'weekly'])
    period?: string;

    @ApiProperty({ example: 1, required: false, description: 'ID danh mục (nếu để trống là hạn mức chung)' })
    @IsOptional()
    @IsNumber()
    categoryId?: number;
}
