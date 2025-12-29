import { Module } from '@nestjs/common';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { JwtModule } from '@nestjs/jwt';
import { JwtStrategy } from './jwt.strategy';
import { PassportModule } from '@nestjs/passport';

@Module({
  controllers: [AuthController],
  providers: [AuthService, JwtStrategy],
  imports: [PassportModule, JwtModule.register({
    secret: process.env.SECRET_KEY,
    signOptions: {
      expiresIn: Number(process.env.JWT_EXPIRES_TTL)
    }
  })],
})
export class AuthModule { }
