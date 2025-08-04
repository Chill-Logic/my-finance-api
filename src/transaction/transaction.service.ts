import { Injectable, NotFoundException } from '@nestjs/common';
import { CreateTransactionDto } from './dto/create-transaction.dto';
import { UpdateTransactionDto } from './dto/update-transaction.dto';
import { DatabaseService } from '../database/database.service';
import { User } from '@prisma/client';

@Injectable()
export class TransactionService {
  constructor(
    private readonly databaseService: DatabaseService
  ) {}

  
  async create(createTransactionDto: CreateTransactionDto, user: User) {
    const wallet = await this.databaseService.wallet.findUnique({
      where: {
        id: createTransactionDto.wallet_id,
        user_wallets: {
          some: {
            user_id: user.id
          }
        }
      }
    })

    if (!wallet) throw new NotFoundException({
      message: 'A carteira informada não foi encontrada'
    });

    return this.databaseService.transaction.create({
      data: createTransactionDto,
    });
  }

  async findAll(wallet_id: string) {
    const transactions = await this.databaseService.transaction.findMany({
      where: { wallet_id }
    });

    const { _sum: { value: depositSum } } = await this.databaseService.transaction.aggregate({
      where: {
        kind: 'deposit',
        wallet_id
      },
      _sum: { value: true }
    });

    const { _sum: { value: withdrawSum } } = await this.databaseService.transaction.aggregate({
      where: {
        kind: 'withdraw',
        wallet_id
      },
      _sum: { value: true }
    });

    return { transactions, total: depositSum - withdrawSum };
  }

  findOne(id: string) {
    return this.databaseService.transaction.findUnique({
      where: { id }
    });
  }

  update(id: string, updateTransactionDto: UpdateTransactionDto) {
    return this.databaseService.transaction.update({
      where: { id },
      data: updateTransactionDto,
    });
  }

  remove(id: string) {
    return this.databaseService.transaction.delete({
      where: { id },
    });
  }
}
