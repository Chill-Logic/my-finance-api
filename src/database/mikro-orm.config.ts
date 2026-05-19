import 'dotenv/config';
import { Options } from '@mikro-orm/core';
import { PostgreSqlDriver } from '@mikro-orm/postgresql';
import { User } from '../app/user/entities/user.entity';
import { Wallet } from '../app/wallet/entities/wallet.entity';
import { UserWallet } from '../app/user-wallet/entities/user-wallet.entity';
import { Transaction } from '../app/transaction/entities/transaction.entity';

const config: Options = {
  driver: PostgreSqlDriver,
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT),
  dbName: process.env.DB_NAME,
  user: process.env.DB_USERNAME,
  password: process.env.DB_PASSWORD,
  driverOptions: {
    connection: {
      options: `-c search_path=${process.env.DB_SCHEMA}`,
    },
  },

  entities: [User, Wallet, UserWallet, Transaction],
  entitiesTs: ['src/**/*.entity.ts'],

  migrations: {
    path: 'dist/migrations',
    pathTs: 'src/migrations',
    glob: '!(*.d).{js,ts}',
    tableName: `${process.env.DB_SCHEMA}.mikro_orm_migrations`,
  },
};

export default config;
