import { Injectable } from '@nestjs/common';
import { CreateWalletDto } from './dto/create-wallet.dto';
import { UpdateWalletDto } from './dto/update-wallet.dto';
import { DatabaseService } from '../database/database.service';

@Injectable()
export class WalletService {
  constructor(
    private readonly databaseService: DatabaseService
  ) {}

  create(createWalletDto: CreateWalletDto) {
    return 'This action adds a new wallet';
  }

  findOneByUserWalletId(id: string) {
    return this.databaseService.wallet.findFirst({
      where: {
        user_wallets: {
          some: { id }
        }
      }
    });
  }

  findAll() {
    return `This action returns all wallet`;
  }

  findOne(id: string) {
    return `This action returns a #${id} wallet`;
  }

  update(id: string, updateWalletDto: UpdateWalletDto) {
    return `This action updates a #${id} wallet`;
  }

  remove(id: string) {
    return `This action removes a #${id} wallet`;
  }
}
