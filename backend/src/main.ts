import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { ValidationPipe } from '@nestjs/common';

import * as admin from 'firebase-admin';
import * as path from 'path';
import * as fs from 'fs';

async function bootstrap() {
  // khoi tao firebase admin
  try {
    const serviceAccountPath = path.join(process.cwd(), 'serviceAccountKey.json');
    if (fs.existsSync(serviceAccountPath)) {
      if (!admin.apps.length) {
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccountPath),
        });
        console.log('Firebase Admin initialized successfully with serviceAccountKey.json');
      }
    } else {
      console.warn('serviceAccountKey.json not found, using default credentials');
      if (!admin.apps.length) admin.initializeApp();
    }
  } catch (error) {
    console.warn(
      'Firebase Admin failed to initialize. Google Sign-In will not work.',
      error.message,
    );
  }

  const app = await NestFactory.create(AppModule);

  // Enable CORS
  app.enableCors();

  // Use ValidationPipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  // Setup Swagger
  const config = new DocumentBuilder()
    .setTitle('Zen API')
    .setDescription('Personal Finance Tracker API documentation')
    .setVersion('1.0')
    .addBearerAuth()
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api', app, document);

  await app.listen(process.env.PORT ?? 3000, '0.0.0.0');
  console.log(`Application is running on: ${await app.getUrl()}`);
  console.log(`Swagger documentation available at: ${await app.getUrl()}/api`);
}
bootstrap();
