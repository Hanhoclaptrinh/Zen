import { IsEnum, IsNumber, IsOptional, IsDateString, IsBoolean, IsArray, ValidateNested, IsString } from "class-validator";
import { ApiProperty } from "@nestjs/swagger";
import { Type } from "class-transformer";
import { SplitDetailDto } from "./split-detail.dto";

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
    @IsString()
    note?: string;

    @ApiProperty({ example: false, required: false })
    @IsOptional()
    @IsBoolean()
    isSplit?: boolean;

    @ApiProperty({ type: [SplitDetailDto], required: false })
    @IsOptional()
    @IsArray()
    @ValidateNested({ each: true })
    @Type(() => SplitDetailDto)
    splitDetails?: SplitDetailDto[];

    @ApiProperty({
        example: 'https://res.cloudinary.com/xxx/image/upload/v123/avatar.jpg',
        required: false,
    })
    @IsOptional()
    @IsString()
    imageUrl?: string;

}