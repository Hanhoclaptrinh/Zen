import {
  BadRequestException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { PrismaService } from 'src/prisma/prisma.service';
import * as bcrypt from 'bcrypt';
import { JwtService } from '@nestjs/jwt';
import { ChangePasswordDto } from './dto/change-password.dto';

import { MailService } from 'src/mail/mail.service';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { GoogleSignInDto } from './dto/google-sign-in.dto';
import * as admin from 'firebase-admin';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private mailService: MailService,
  ) {}

  // google sign in logic
  async googleSignIn(dto: GoogleSignInDto) {
    try {
      const decodedToken = await admin.auth().verifyIdToken(dto.idToken);
      const { email, name, picture } = decodedToken;

      if (!email) {
        throw new BadRequestException('Email not found in Google Token');
      }

      // check if user exists
      let user = await this.prisma.user.findUnique({
        where: { email },
      });

      if (!user) {
        // create new user if not exists
        user = await this.prisma.user.create({
          data: {
            email,
            fullName: name || email.split('@')[0],
            avatarUrl: picture,
            passwordHash: null as any,
          },
        });
      }

      // generate zen jwt token
      const accessToken = this.signToken(user.id);
      return { accessToken };
    } catch (error) {
      console.error('Google Sign-In Error:', error);
      throw new UnauthorizedException('Invalid Google Token');
    }
  }

  // register logic
  async register(dto: RegisterDto) {
    // check email exists
    const existingUser = await this.prisma.user.findUnique({
      where: {
        email: dto.email,
      },
    });

    if (existingUser) {
      throw new BadRequestException('Email already exists');
    }

    // hash password
    const hashedPassword = await bcrypt.hash(dto.password, 10);

    // create user
    const user = await this.prisma.user.create({
      data: {
        email: dto.email,
        passwordHash: hashedPassword,
        fullName: dto.fullName,
      },

      select: {
        id: true,
        email: true,
        fullName: true,
        avatarUrl: true,
        createdAt: true,
      },
    });

    // sign jwt
    const accessToken = this.signToken(user.id);

    // return token & user
    return { accessToken };
  }

  // login logic
  async login(dto: LoginDto) {
    // find user
    const user = await this.prisma.user.findUnique({
      where: {
        email: dto.email,
      },
    });

    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // compare password
    const isPasswordValid = await bcrypt.compare(
      dto.password,
      user.passwordHash,
    );

    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // sign jwt
    const accessToken = this.signToken(user.id);

    // return token
    return { accessToken };
  }

  // verify logic
  async validateUser(userId: number) {
    const user = await this.prisma.user.findUnique({
      where: {
        id: userId,
      },

      select: {
        id: true,
        email: true,
        fullName: true,
        avatarUrl: true,
        createdAt: true,
      },
    });

    if (!user) {
      throw new UnauthorizedException('Invalid token');
    }

    return user;
  }

  // update profile logic
  async updateProfile(userId: number, dto: UpdateProfileDto) {
    return this.prisma.user.update({
      where: { id: userId },
      // cho phep cap nhat fullname va avatar
      data: {
        ...(dto.fullName && { fullName: dto.fullName }),
        ...(dto.avatarUrl && { avatarUrl: dto.avatarUrl }),
      },
      select: {
        id: true,
        email: true,
        fullName: true,
        avatarUrl: true,
        createdAt: true,
      },
    });
  }

  // change password logic
  async changePassword(userId: number, dto: ChangePasswordDto) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new UnauthorizedException('User not found');
    }

    const isPasswordValid = await bcrypt.compare(
      dto.oldPassword,
      user.passwordHash,
    );

    if (!isPasswordValid) {
      throw new BadRequestException('Incorrect old password');
    }

    const hashedPassword = await bcrypt.hash(dto.newPassword, 10);

    await this.prisma.user.update({
      where: { id: userId },
      data: { passwordHash: hashedPassword },
    });

    return { message: 'Password changed successfully' };
  }

  // forgot password logic
  async forgotPassword(email: string) {
    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user) {
      throw new BadRequestException('Email not found');
    }

    // generate 4 digit otp
    const otp = Math.floor(1000 + Math.random() * 9000).toString();
    const expires = new Date();
    expires.setMinutes(expires.getMinutes() + 5); // 5 mins

    await this.prisma.user.update({
      where: { email },
      data: {
        resetCode: otp,
        resetCodeExpires: expires,
      },
    });

    // send email
    await this.mailService.sendOtp(email, otp);

    return { message: 'OTP sent to email' };
  }

  // verify otp logic
  async verifyOtp(email: string, otp: string) {
    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user || user.resetCode !== otp) {
      throw new BadRequestException('Invalid OTP');
    }

    if (user.resetCodeExpires && user.resetCodeExpires < new Date()) {
      throw new BadRequestException('OTP expired');
    }

    return { message: 'OTP valid' };
  }

  // reset password logic
  async resetPassword(dto: ResetPasswordDto) {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });

    if (!user || user.resetCode !== dto.otp) {
      throw new BadRequestException('Invalid OTP');
    }

    if (user.resetCodeExpires && user.resetCodeExpires < new Date()) {
      throw new BadRequestException('OTP expired');
    }

    const hashedPassword = await bcrypt.hash(dto.newPassword, 10);

    await this.prisma.user.update({
      where: { email: dto.email },
      data: {
        passwordHash: hashedPassword,
        resetCode: null,
        resetCodeExpires: null,
      },
    });

    return { message: 'Password reset successfully' };
  }

  // sign token logic
  private signToken(userId: number) {
    return this.jwtService.sign({
      sub: userId,
    });
  }
}
