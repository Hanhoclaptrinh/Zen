import { IsEnum, IsOptional, IsString } from "class-validator";

export class UpdateCategoryDto {
    @IsOptional()
    @IsString()
    name: string;

    @IsOptional()
    @IsEnum(['income', 'expense'])
    type: 'income' | 'expense';
}