import { Module } from '@nestjs/common';
import { UserService } from './user.service';
import { UserController } from './user.controller';
import { UserSubscriber } from './user.subscriber';

@Module({
  controllers: [UserController],
  providers: [UserService, UserSubscriber],
  exports: [UserService]
})
export class UserModule {}
