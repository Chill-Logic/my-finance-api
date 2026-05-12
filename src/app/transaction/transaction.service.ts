import { Injectable, NotFoundException } from '@nestjs/common';
import { CreateTransactionDto } from './dto/create-transaction.dto';
import { UpdateTransactionDto } from './dto/update-transaction.dto';
import { EntityManager } from '@mikro-orm/postgresql';
import { User } from '../user/entities/user.entity';
import { Wallet } from '../wallet/entities/wallet.entity';
import { Transaction, TransactionKind } from './entities/transaction.entity';
import { QueryWalletIdDto } from './dto/query-wallet-id.dto';
import { FilterQuery, raw, wrap } from '@mikro-orm/core';

@Injectable()
export class TransactionService {
  constructor(
    private readonly em: EntityManager
  ) {}

  
  async create(createTransactionDto: CreateTransactionDto, user: User) {
    const wallet = await this.em.findOne(Wallet, {
      id: createTransactionDto.wallet_id,
      user_wallets: { user: user.id }
    });

    if (!wallet) throw new NotFoundException({
      message: 'A carteira informada não foi encontrada'
    });

    createTransactionDto.transaction_date.setUTCHours(3, 0, 0, 0);

    const { wallet_id, ...rest } = createTransactionDto;
    const transaction = this.em.create(Transaction, {
      ...rest,
      wallet: wallet_id,
      user: user.id,
    });

    await this.em.flush();
    return transaction;
  }

  async findAll({ wallet_id, start_date, end_date }: QueryWalletIdDto, user: User) {
    const wallet = await this.em.findOne(Wallet, {
      id: wallet_id,
      user_wallets: { user: user.id }
    });

    if (!wallet) throw new NotFoundException({
      message: 'A carteira informada não foi encontrada'
    });

    if (start_date) start_date.setUTCHours(3, 0, 0, 0);
    if (end_date) {
      end_date?.setDate(end_date.getDate() + 1)
      end_date.setUTCHours(3, 0, 0, 0);
    }

    const transactionQuery: FilterQuery<Transaction> = {
      wallet: wallet_id,
      ...(start_date || end_date ? {
        transaction_date: {
          ...(start_date && { $gte: start_date }),
          ...(end_date && { $lt: end_date }),
        }
      } : {}),
    };

    const transactions = await this.em.find(Transaction, transactionQuery, {
      orderBy: { transaction_date: 'DESC' },
      populate: ['user'],
    });

    const depositSum = await this.sumTransactions(wallet_id, TransactionKind.DEPOSIT, start_date, end_date);
    const withdrawSum = await this.sumTransactions(wallet_id, TransactionKind.WITHDRAW, start_date, end_date);

    return { transactions, total: depositSum - withdrawSum };
  }

  async findOne(id: string, user: User) {
    const transaction = await this.em.findOne(Transaction, {
      id,
      wallet: { user_wallets: { user: user.id } }
    });

    if (!transaction) throw new NotFoundException({
      message: 'A transação informada não foi encontrada'
    });

    return transaction;
  }

  async update(id: string, updateTransactionDto: UpdateTransactionDto, user: User) {
    const transaction = await this.em.findOne(Transaction, {
      id,
      wallet: { user_wallets: { user: user.id } }
    });

    if (!transaction) throw new NotFoundException({
      message: 'A transação informada não foi encontrada'
    });

    if (updateTransactionDto.transaction_date) {
      updateTransactionDto.transaction_date.setUTCHours(3, 0, 0, 0);
    }

    wrap(transaction).assign(updateTransactionDto);
    await this.em.flush();

    return transaction;
  }

  async remove(id: string, user: User) {
    const transaction = await this.em.findOne(Transaction, {
      id,
      wallet: { user_wallets: { user: user.id } }
    });

    if (!transaction) throw new NotFoundException({
      message: 'A transação informada não foi encontrada'
    });

    await this.em.remove(transaction).flush;
  }

  private async sumTransactions(
    walletId: string,
    kind: TransactionKind,
    startDate?: Date,
    endDate?: Date,
  ): Promise<number> {
    const qb = this.em
      .createQueryBuilder(Transaction)
      .select(raw('sum(value) as total'))
      .where({ wallet: walletId, kind });

    if (startDate) qb.andWhere({ transaction_date: { $gte: startDate } });
    if (endDate) qb.andWhere({ transaction_date: { $lt: endDate } });

    const result = await qb.execute<{ total: string }>('get');
    return Number(result?.total) || 0;
  }
}
