import { IsEmail, IsNotEmpty, Length, MinLength } from 'class-validator';

export class ResetPasswordDto {
  @IsEmail()
  @IsNotEmpty()
  email: string;

  @IsNotEmpty()
  @Length(4, 4)
  otp: string;

  @IsNotEmpty()
  @MinLength(6)
  newPassword: string;
}
