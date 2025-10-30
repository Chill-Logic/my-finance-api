import { Injectable, NotFoundException } from '@nestjs/common';
import { CreateWalletDto } from './dto/create-wallet.dto';
import { UpdateWalletDto } from './dto/update-wallet.dto';
import { DatabaseService } from '../database/database.service';
import { User } from '@prisma/client';

@Injectable()
export class WalletService {
  constructor(
    private readonly databaseService: DatabaseService
  ) {}

  create(createWalletDto: CreateWalletDto, user: User) {
    return this.databaseService.wallet.create({
      data: {
        owner_id: user.id,
        name: createWalletDto.name,
        user_wallets: {
          create: {
            accepted: true,
            user_id: user.id
          }
        }
      }
    })
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

  async findAll(user: User) {
    const wallets = await this.databaseService.wallet.findMany({
      where: {
        user_wallets: {
          some: {
            accepted: true,
            user_id: user.id
          }
        }
      }
    });

    const walletsWithTotal = await Promise.all(wallets.map(async (wallet) => {
      const { _sum: { value: depositSum } } = await this.databaseService.transaction.aggregate({
        where: { wallet_id: wallet.id, kind: 'deposit' },
        _sum: { value: true }
      });
      const { _sum: { value: withdrawSum } } = await this.databaseService.transaction.aggregate({
        where: { wallet_id: wallet.id, kind: 'withdraw' },
        _sum: { value: true }
      });

      return { ...wallet, total: depositSum - withdrawSum };
    }));

    return walletsWithTotal;
  }

  // findOne(id: string) {
  //   return `This action returns a #${id} wallet`;
  // }

  async update(id: string, updateWalletDto: UpdateWalletDto, user: User) {
    const walletExists = await this.databaseService.wallet.findUnique({
      where: {
        id,
        owner_id: user.id
      }
    });

    if (!walletExists) throw new NotFoundException({
      message: 'A carteira informada não foi encontrada'
    });

    const wallet = await this.databaseService.wallet.update({
      where: {
        id,
        owner_id: user.id
      },
      data: {
        name: updateWalletDto.name
      }
    });

    return wallet;
  }

  // remove(id: string) {
  //   return `This action removes a #${id} wallet`;
  // }
}
