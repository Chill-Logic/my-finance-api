import { Injectable, NotFoundException } from '@nestjs/common';
import { CreateTransactionDto } from './dto/create-transaction.dto';
import { UpdateTransactionDto } from './dto/update-transaction.dto';
import { DatabaseService } from '../database/database.service';
import { Prisma, User } from '@prisma/client';
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

    createTransactionDto.transaction_date.setUTCHours(3, 0, 0, 0);

    return this.databaseService.transaction.create({
      data: { ...createTransactionDto, user_id: user.id },
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

    if (start_date) start_date.setUTCHours(3, 0, 0, 0);
    if (end_date) {
      end_date?.setDate(end_date.getDate() + 1)
      end_date.setUTCHours(3, 0, 0, 0);
    }

    const transactionQuery: Prisma.TransactionWhereInput = {
      wallet_id,
      transaction_date: {
        gte: start_date,
        lt: end_date,
      }
    }

    const transactions = await this.databaseService.transaction.findMany({
      where: transactionQuery,
      orderBy: { transaction_date: 'desc' },
      include: { user: { select: { name: true, email: true } } }
    });

    const { _sum: { value: depositSum } } = await this.databaseService.transaction.aggregate({
      where: {
        kind: 'deposit',
        ...transactionQuery
      },
      _sum: { value: true }
    });

    const { _sum: { value: withdrawSum } } = await this.databaseService.transaction.aggregate({
      where: {
        kind: 'withdraw',
        ...transactionQuery
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

    if (updateTransactionDto.transaction_date) {
      updateTransactionDto.transaction_date.setUTCHours(3, 0, 0, 0);
    }

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
