import { Injectable, NotFoundException } from '@nestjs/common';
import { CreateWalletDto } from './dto/create-wallet.dto';
import { UpdateWalletDto } from './dto/update-wallet.dto';
import { EntityManager } from '@mikro-orm/postgresql';
import { User } from '../user/entities/user.entity';
import { Wallet } from './entities/wallet.entity';
import { Transaction, TransactionKind } from '../transaction/entities/transaction.entity';
import { raw, wrap } from '@mikro-orm/core';

@Injectable()
export class WalletService {
  constructor(
    private readonly em: EntityManager
  ) {}

  async create(createWalletDto: CreateWalletDto, user: User) {
    const wallet = this.em.create(Wallet, {
      name: createWalletDto.name,
      owner: user.id,
      user_wallets: [{ user: user.id, accepted: true }],
    });

    await this.em.flush();
    return wallet;
  }

  async findOneByUserWalletId(id: string) {
    return this.em.findOne(Wallet, {
      user_wallets: { id }
    });
  }

  async findAll(user: User) {
    const wallets = await this.em.find(Wallet, {
      user_wallets: {
        accepted: true,
        user: user.id
      }
    });

    const walletsWithTotal = await Promise.all(wallets.map(async (wallet) => {
      const depositResult = await this.em
        .createQueryBuilder(Transaction)
        .select(raw('sum(value) as total'))
        .where({ wallet: wallet.id, kind: TransactionKind.DEPOSIT })
        .execute<{ total: string }>('get');

      const withdrawResult = await this.em
        .createQueryBuilder(Transaction)
        .select(raw('sum(value) as total'))
        .where({ wallet: wallet.id, kind: TransactionKind.WITHDRAW })
        .execute<{ total: string }>('get');

      const depositSum = Number(depositResult?.total) || 0;
      const withdrawSum = Number(withdrawResult?.total) || 0;

      return { ...wrap(wallet).toObject(), total: depositSum - withdrawSum };
    }));

    return walletsWithTotal;
  }

  async update(id: string, updateWalletDto: UpdateWalletDto, user: User) {
    const wallet = await this.em.findOne(Wallet, {
      id,
      owner: user.id
    });

    if (!wallet) throw new NotFoundException({
      message: 'A carteira informada não foi encontrada'
    });

    wrap(wallet).assign({ name: updateWalletDto.name });
    await this.em.flush();

    return wallet;
  }
}
