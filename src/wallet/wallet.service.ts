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

  async findOneByUserWalletId(id: string) {
    const wallet = await this.databaseService.wallet.findFirst({
      where: {
        user_wallets: {
          some: { id }
        }
      },
      include: {
        transactions: true
      }
    });

    const { _sum: { value: depositSum } } = await this.databaseService.transaction.aggregate({
      where: {
        kind: 'deposit',
        wallet_id: wallet.id
      },
      _sum: { value: true }
    });

    const { _sum: { value: withdrawSum } } = await this.databaseService.transaction.aggregate({
      where: {
        kind: 'withdraw',
        wallet_id: wallet.id
      },
      _sum: { value: true }
    });

    return { ...wallet, total: depositSum - withdrawSum };
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
