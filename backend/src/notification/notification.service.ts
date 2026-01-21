import { Injectable, Logger } from '@nestjs/common';
import { DevicePlatform } from '@prisma/client';
import * as admin from 'firebase-admin';
import { PrismaService } from 'src/prisma/prisma.service';

@Injectable()
export class NotificationService {
  private readonly logger = new Logger(NotificationService.name);
  constructor(private readonly prisma: PrismaService) {}

  async sendToUser(userId: number, payload: {
    title: string;
    body: string;
    data?: Record<string, string>;
  }) {
    // lay tat ca token cua user
    const deviceTokens = await this.prisma.deviceToken.findMany({
      where: {userId},
    });

    if (deviceTokens.length === 0) {
      this.logger.warn(`Khong co token nao de gui thong bao cho user ${userId}`)
      return;
    }

    const tokens = deviceTokens.map(t => t.token);

    // gui thong bao
    const response = await admin.messaging().sendEachForMulticast({
      tokens,
      notification: {
        title: payload.title,
        body: payload.body,
      },
      data: payload.data,
      android: {
        priority: 'high',
      },
      apns: {
        headers: {
          'apns-priority': '10',
        },

        payload: {
          aps: {
           sound: 'default', 
          }
        }
      },
    });

    // don dep token loi (user xoa app)
    if (response.failureCount > 0) {
      const removeTokens: string[] = [];

      response.responses.forEach((res, idx) => {
        if (!res.success) {
          const error = res.error;
          if (
            error?.code === 'messaging/registration-token-not-registered' ||
            error?.code === 'messaging/invalid-registration-token'
          ) {
            removeTokens.push(tokens[idx]);
          }
        }
      });

      if (removeTokens.length > 0) {
        await this.prisma.deviceToken.deleteMany({
          where: {
            token: {
              in: removeTokens,
            },
          },
        });

        this.logger.log(`Da xoa ${removeTokens.length} token loi cua user ${userId}`);
      }
    }

    return response;
  }

  // luu token vao db
  async saveDeviceToken(userId: number, token: string, platform: DevicePlatform) {
    return this.prisma.deviceToken.upsert({
      where: { token: token }, // token la unique
      update: {
        userId: userId,
        platform: platform,
      },
      create: {
        token: token,
        platform: platform,
        userId: userId,
      },
    })
  }

  // huy dang ky thiet bi
  async removeDeviceToken(token: string) {
    return this.prisma.deviceToken.delete({
      where: { token: token },
    })
  }
}
