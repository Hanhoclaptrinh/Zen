import { IsEnum, IsNumber, IsOptional, IsDateString } from "class-validator";
import { ApiProperty } from "@nestjs/swagger";

export class CreateTransactionDto {
    @ApiProperty({ example: 50000 })
    @IsNumber()
    amount: number;

    // loai giao dich: thu nhap hoac chi tieu
    @ApiProperty({ enum: ['income', 'expense'], example: 'expense' })
    @IsEnum(['income', 'expense'])
    type: 'income' | 'expense';

    @ApiProperty({ example: 1, description: 'ID of the category' })
    @IsNumber()
    categoryId: number;

    @ApiProperty({ example: '2026-01-15T16:25:00.000Z' })
    @IsDateString()
    transactionDate: string;

    // ghi chu giao dich
    @ApiProperty({ example: 'Ăn trưa', required: false })
    @IsOptional()
    note?: string;
}