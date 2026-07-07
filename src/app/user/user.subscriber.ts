import { Injectable } from '@nestjs/common';
import {
  EntityManager,
  EventSubscriber,
  FlushEventArgs,
  ChangeSetType,
  EventArgs,
} from '@mikro-orm/core';
import { User } from './entities/user.entity';
import { Wallet } from '../wallet/entities/wallet.entity';
import { UserWallet } from '../user-wallet/entities/user-wallet.entity';

@Injectable()
export class UserSubscriber implements EventSubscriber<User> {
  constructor(em: EntityManager) {
    em.getEventManager().registerSubscriber(this);
  }

  getSubscribedEntities() {
    return [User];
  }

  async onFlush(args: FlushEventArgs): Promise<void> {
    const { uow } = args;

    const newUsers = uow
      .getChangeSets()
      .filter((cs) => cs.type === ChangeSetType.CREATE && cs.entity instanceof User)
      .map((cs) => cs.entity as User);

    for (const user of newUsers) {
      const wallet = new Wallet();
      wallet.name = 'Minha Carteira';
      wallet.owner = user;

      const userWallet = new UserWallet();
      userWallet.user = user;
      userWallet.wallet = wallet;
      userWallet.accepted = true;

      user.main_user_wallet = userWallet;

      uow.computeChangeSet(wallet);
      uow.computeChangeSet(userWallet);
      uow.recomputeSingleChangeSet(user);
    }
  }
}
