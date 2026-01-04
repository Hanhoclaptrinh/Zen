import { Injectable } from '@nestjs/common';
import * as nodemailer from 'nodemailer';

@Injectable()
export class MailService {
  private transporter;

  constructor() {
    this.transporter = nodemailer.createTransport({
      host: process.env.SMTP_HOST || 'smtp.gmail.com',
      port: Number(process.env.SMTP_PORT) || 587,
      secure: true,
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS,
      },
    });
  }

  async sendOtp(email: string, otp: string) {
    if (!process.env.SMTP_USER) {
      console.log(`[Mock Mail] To: ${email}, OTP: ${otp}`);
      return;
    }

    try {
      // payload gui cho user qua email
      await this.transporter.sendMail({
        from: 'Zen - Expense Tracking App <no-reply@zenapp.com>',
        to: email,
        subject: 'Your Password Reset OTP',
        text: `Your OTP code is: ${otp}. It expires in 5 minutes.`,
        html: `<b>Your OTP code is: ${otp}</b><br>It expires in 5 minutes.`,
      });
      // console.log(`Email sent to ${email}`);
    } catch (error) {
      console.error('Error sending email:', error);
      // log err
      console.log(`[Fallback] To: ${email}, OTP: ${otp}`);
    }
  }
}
