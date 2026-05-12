import { Entity, PrimaryKey, Property, ManyToOne, OneToMany, Collection } from '@mikro-orm/core';
import { User } from '../../user/entities/user.entity';
import { Transaction } from '../../transaction/entities/transaction.entity';
import { UserWallet } from '../../user-wallet/entities/user-wallet.entity';

@Entity({ tableName: 'wallets' })
export class Wallet {
  @PrimaryKey({ type: 'uuid', defaultRaw: 'gen_random_uuid()' })
  id: string;

  @Property()
  name: string;

  @ManyToOne(() => User)
  owner: User;

  @OneToMany(() => Transaction, t => t.wallet)
  transactions = new Collection<Transaction>(this);

  @OneToMany(() => UserWallet, uw => uw.wallet)
  user_wallets = new Collection<UserWallet>(this);

  @Property()
  created_at: Date = new Date();

  @Property({ onUpdate: () => new Date() })
  updated_at: Date = new Date();

  @Property({ nullable: true })
  discarded_at?: Date;
}
