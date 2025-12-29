import { IsEnum, IsString } from "class-validator";

export class CreateCategoryDto {
    @IsString()
    name: string;

    // loai giao dich
    @IsEnum(['income', 'expense'])
    type: 'income' | 'expense';
}