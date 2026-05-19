import { Entity, PrimaryKey, Property, ManyToOne, OneToMany, Collection } from '@mikro-orm/core';
import { UserWallet } from '../../user-wallet/entities/user-wallet.entity';
import { Wallet } from '../../wallet/entities/wallet.entity';
import { Transaction } from '../../transaction/entities/transaction.entity';

@Entity({ tableName: 'users' })
export class User {
  @PrimaryKey({ type: 'uuid', defaultRaw: 'gen_random_uuid()' })
  id: string;

  @Property({ unique: true })
  email: string;

  @Property()
  name: string;

  @Property({ hidden: true })
  password: string;

  @ManyToOne(() => UserWallet, { nullable: true })
  main_user_wallet?: UserWallet;

  @OneToMany(() => UserWallet, uw => uw.user)
  user_wallets = new Collection<UserWallet>(this);

  @OneToMany(() => Transaction, t => t.user)
  my_transactions = new Collection<Transaction>(this);

  @OneToMany(() => Wallet, w => w.owner)
  my_wallets = new Collection<Wallet>(this);

  @Property()
  created_at: Date = new Date();

  @Property({ onUpdate: () => new Date() })
  updated_at: Date = new Date();

  @Property({ nullable: true })
  discarded_at?: Date;
}
