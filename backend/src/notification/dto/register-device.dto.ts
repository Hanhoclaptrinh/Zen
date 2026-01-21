import { IsEnum, IsNotEmpty, IsString } from "class-validator";

export enum DevicePlatform {
    IOS = 'ios',
    ANDROID = 'android',
    WEB = 'web',
}

export class RegisterDeviceDto {
    @IsString()
    @IsNotEmpty()
    token: string;

    @IsEnum(DevicePlatform)
    platform: DevicePlatform;
}