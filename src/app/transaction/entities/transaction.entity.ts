import { Entity, PrimaryKey, Property, ManyToOne, Enum } from '@mikro-orm/core';
import { Wallet } from '../../wallet/entities/wallet.entity';
import { User } from '../../user/entities/user.entity';

export enum TransactionKind {
  DEPOSIT = 'deposit',
  WITHDRAW = 'withdraw',
}

@Entity({ tableName: 'transactions' })
export class Transaction {
  @PrimaryKey({ type: 'uuid', defaultRaw: 'gen_random_uuid()' })
  id: string;

  @Property()
  description: string;

  @Property({ type: 'int' })
  value: number;

  @Enum(() => TransactionKind)
  kind: TransactionKind;

  @ManyToOne(() => Wallet)
  wallet: Wallet;

  @Property()
  transaction_date: Date;

  @ManyToOne(() => User)
  user: User;

  @Property()
  created_at: Date = new Date();

  @Property({ onUpdate: () => new Date() })
  updated_at: Date = new Date();

  @Property({ nullable: true })
  discarded_at?: Date;
}
