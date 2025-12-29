import { IsEnum, IsNumber, IsOptional, IsDateString } from "class-validator";

export class CreateTransactionDto {
    @IsNumber()
    amount: number;

    // loai giao dich: thu nhap hoac chi tieu
    @IsEnum(['income', 'expense'])
    type: 'income' | 'expense';

    @IsNumber()
    categoryId: number;

    @IsDateString()
    transactionDate: string;

    // ghi chu giao dich
    @IsOptional()
    note?: string;
}