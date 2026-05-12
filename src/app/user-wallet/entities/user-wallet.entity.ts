import { Entity, PrimaryKey, Property, ManyToOne, OneToMany, Collection } from '@mikro-orm/core';
import { User } from '../../user/entities/user.entity';
import { Wallet } from '../../wallet/entities/wallet.entity';

@Entity({ tableName: 'user_wallets' })
export class UserWallet {
  @PrimaryKey({ type: 'uuid', defaultRaw: 'gen_random_uuid()' })
  id: string;

  @ManyToOne(() => User)
  user: User;

  @ManyToOne(() => Wallet)
  wallet: Wallet;

  @OneToMany(() => User, u => u.main_user_wallet)
  users_main_wallet = new Collection<User>(this);

  @Property({ default: false })
  accepted: boolean = false;

  @Property()
  created_at: Date = new Date();

  @Property({ onUpdate: () => new Date() })
  updated_at: Date = new Date();

  @Property({ nullable: true })
  discarded_at?: Date;
}
