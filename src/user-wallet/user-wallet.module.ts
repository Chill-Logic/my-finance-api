import { Module } from '@nestjs/common';
import { UserWalletService } from './user-wallet.service';
import { UserWalletController } from './user-wallet.controller';

@Module({
  controllers: [UserWalletController],
  providers: [UserWalletService],
})
export class UserWalletModule {}
