import { MiddlewareConsumer, Module, RequestMethod } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './auth/auth.module';
import { UserModule } from './user/user.module';
import { APP_GUARD } from '@nestjs/core';
import { JwtAuthGuard } from './auth/jwt-auth.guard';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { LoggerMiddleware } from '../middleware/logger.middleware';
import { TransactionModule } from './transaction/transaction.module';
import { WalletModule } from './wallet/wallet.module';
import { UserWalletModule } from './user-wallet/user-wallet.module';
import { join } from 'path';
import { MikroOrmModule } from '@mikro-orm/nestjs';
import { PostgreSqlDriver } from '@mikro-orm/postgresql';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: join(__dirname, '../../.env')
    }),
    AuthModule,
    UserModule,
    TransactionModule,
    WalletModule,
    UserWalletModule,
    MikroOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        driver: PostgreSqlDriver,
        host: config.getOrThrow<string>('DB_HOST'),
        port: config.getOrThrow<number>('DB_PORT'),
        dbName: config.getOrThrow<string>('DB_NAME'),
        schema: config.getOrThrow<string>('DB_SCHEMA'),
        user: config.getOrThrow<string>('DB_USERNAME'),
        password: config.getOrThrow<string>('DB_PASSWORD'),
        
        entities: ['dist/**/*.entity.js'],
        entitiesTs: ['src/**/*.entity.ts'],

        migrations: {
          path: 'dist/migrations',
          pathTs: 'src/migrations',
          glob: '!(*.d).{js,ts}',
        },
      }),
    })
  ],
  controllers: [AppController],
  providers: [
    AppService,
    {
      provide: APP_GUARD,
      useClass: JwtAuthGuard,
    }
  ]
})
export class AppModule {
  configure(consumer: MiddlewareConsumer) {
    consumer
      .apply(LoggerMiddleware)
      .forRoutes({ path: "*", method: RequestMethod.ALL });
  }
}