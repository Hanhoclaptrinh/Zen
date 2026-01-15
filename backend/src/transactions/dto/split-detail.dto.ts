import { IsBoolean, IsNumber, IsOptional, IsString } from "class-validator";
import { ApiProperty } from "@nestjs/swagger";

export class SplitDetailDto {
    @ApiProperty({ example: 'Nguyễn Văn A' })
    @IsString()
    name: string;

    @ApiProperty({ example: 50000 })
    @IsNumber()
    amount: number;

    @ApiProperty({ example: false, required: false })
    @IsOptional()
    @IsBoolean()
    isPaid?: boolean;
}
