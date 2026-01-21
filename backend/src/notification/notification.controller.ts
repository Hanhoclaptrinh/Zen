import { Body, Controller, Post, Req, UseGuards } from '@nestjs/common';
import { NotificationService } from './notification.service';
import { JwtAuthGuard } from 'src/auth/jwt-auth.guard';
import { RegisterDeviceDto } from './dto/register-device.dto';
import type { AuthRequest } from 'src/common/types/auth-request';

@Controller('notification')
@UseGuards(JwtAuthGuard)
export class NotificationController {
    constructor(private readonly notificationService: NotificationService) {}

    // dang ky thiet bi
    @Post('register-device')
    async registerDevice(@Req() req: AuthRequest, @Body() body: RegisterDeviceDto) {
        const userId = req.user.id;
        return this.notificationService.saveDeviceToken(userId, body.token, body.platform);
    }

    // huy dang ky thiet bi
    @Post('unregister-device')
    async unregisterDevice(@Body() body: { token: string }) {
        return this.notificationService.removeDeviceToken(body.token);
    }
}
