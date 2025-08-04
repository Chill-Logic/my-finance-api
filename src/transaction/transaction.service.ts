import { Injectable, NotFoundException } from '@nestjs/common';
import { CreateTransactionDto } from './dto/create-transaction.dto';
import { UpdateTransactionDto } from './dto/update-transaction.dto';
import { DatabaseService } from '../database/database.service';
import { User } from '@prisma/client';
import { QueryWalletIdDto } from './dto/query-wallet-id.dto';

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

  async findAll({ wallet_id, start_date, end_date }: QueryWalletIdDto, user: User) {
    const wallet = await this.databaseService.wallet.findUnique({
      where: {
        id: wallet_id,
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

    start_date = start_date ? new Date(start_date) : undefined;
    start_date?.setUTCHours(3, 0, 0, 0);

    end_date = end_date ? new Date(end_date) : undefined;
    end_date?.setDate(end_date.getDate() + 1);
    end_date?.setUTCHours(3, 0, 0, 0);

    const transactions = await this.databaseService.transaction.findMany({
      where: {
        wallet_id,
        transaction_date: {
          gte: start_date,
          lt: end_date,
        }
      },
      orderBy: { transaction_date: 'desc' }
    });

    const { _sum: { value: depositSum } } = await this.databaseService.transaction.aggregate({
      where: {
        kind: 'deposit',
        wallet_id,
        transaction_date: {
          gte: start_date,
          lt: end_date,
        }
      },
      _sum: { value: true }
    });

    const { _sum: { value: withdrawSum } } = await this.databaseService.transaction.aggregate({
      where: {
        kind: 'withdraw',
        wallet_id,
        transaction_date: {
          gte: start_date,
          lt: end_date,
        }
      },
      _sum: { value: true }
    });

    return { transactions, total: depositSum - withdrawSum };
  }

  async findOne(id: string, user: User) {
    const transaction = await this.databaseService.transaction.findUnique({
      where: {
        id,
        wallet: {
          user_wallets: {
            some: {
              user_id: user.id
            }
          }
        }
      }
    });

    if (!transaction) throw new NotFoundException({
      message: 'A transação informada não foi encontrada'
    });

    return transaction;
  }

  async update(id: string, updateTransactionDto: UpdateTransactionDto, user: User) {
    const transactionExists = await this.databaseService.transaction.findUnique({
      where: {
        id,
        wallet: {
          user_wallets: {
            some: {
              user_id: user.id
            }
          }
        }
      }
    });

    if (!transactionExists) throw new NotFoundException({
      message: 'A transação informada não foi encontrada'
    });

    const transaction = await this.databaseService.transaction.update({
      where: {
        id,
        wallet: {
          user_wallets: {
            some: {
              user_id: user.id
            }
          }
        }
      },
      data: updateTransactionDto,
    });

    return transaction;
  }

  async remove(id: string, user: User) {
    const transaction = await this.databaseService.transaction.deleteMany({
      where: {
        id,
        wallet: {
          user_wallets: {
            some: {
              user_id: user.id
            }
          }
        }
      },
    });

    if (!transaction.count) throw new NotFoundException({
      message: 'A transação informada não foi encontrada'
    });

    return transaction;
  }
}
