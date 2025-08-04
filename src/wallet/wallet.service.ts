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

  findAll(user: User) {
    return this.databaseService.wallet.findMany({
      where: {
        user_wallets: {
          some: {
            accepted: true,
            user_id: user.id
          }
        }
      }
    });
  }

  // findOne(id: string) {
  //   return `This action returns a #${id} wallet`;
  // }

  async update(id: string, updateWalletDto: UpdateWalletDto, user: User) {
    const wallet = await this.databaseService.wallet.updateMany({
      where: {
        id,
        owner_id: user.id
      },
      data: {
        name: updateWalletDto.name
      }
    })

    if (!wallet.count) throw new NotFoundException({
      message: 'A carteira informada não foi encontrada'
    })

    return wallet;
  }

  // remove(id: string) {
  //   return `This action removes a #${id} wallet`;
  // }
}
