import { NestFactory } from '@nestjs/core';
import { AppModule } from './app/app.module';
import { NestExpressApplication } from '@nestjs/platform-express';
import { HttpStatus, ValidationPipe } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule, {
    logger: ['error', 'warn', 'log', 'debug', 'verbose']
  });

  app.useGlobalPipes(new ValidationPipe({
    transform: true,
    errorHttpStatusCode: HttpStatus.UNPROCESSABLE_ENTITY,
    stopAtFirstError: true
  }));

  app.enableCors({
    // em dev: reflete a origem do front (localhost:qualquer-porta).
    // em prod: defina CORS_ORIGINS="https://app.seudominio.com,https://..."
    origin: process.env.CORS_ORIGINS
      ? process.env.CORS_ORIGINS.split(',').map((o) => o.trim())
      : true,
    credentials: true,
  });

  await app.listen(process.env.PORT ?? 3000);
}
bootstrap();