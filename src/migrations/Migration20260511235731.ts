import { Migration } from '@mikro-orm/migrations';

export class Migration20260511235731 extends Migration {

  override async up(): Promise<void> {
    this.addSql(`create schema if not exists "my_finance_dev";`);
    this.addSql(`create table "my_finance_dev"."wallets" ("id" uuid not null default gen_random_uuid(), "name" varchar(255) not null, "owner_id" uuid not null, "created_at" timestamptz not null, "updated_at" timestamptz not null, "discarded_at" timestamptz null, constraint "wallets_pkey" primary key ("id"));`);

    this.addSql(`create table "my_finance_dev"."users" ("id" uuid not null default gen_random_uuid(), "email" varchar(255) not null, "name" varchar(255) not null, "password" varchar(255) not null, "main_user_wallet_id" uuid null, "created_at" timestamptz not null, "updated_at" timestamptz not null, "discarded_at" timestamptz null, constraint "users_pkey" primary key ("id"));`);
    this.addSql(`alter table "my_finance_dev"."users" add constraint "users_email_unique" unique ("email");`);

    this.addSql(`create table "my_finance_dev"."user_wallets" ("id" uuid not null default gen_random_uuid(), "user_id" uuid not null, "wallet_id" uuid not null, "accepted" boolean not null default false, "created_at" timestamptz not null, "updated_at" timestamptz not null, "discarded_at" timestamptz null, constraint "user_wallets_pkey" primary key ("id"));`);

    this.addSql(`create table "my_finance_dev"."transactions" ("id" uuid not null default gen_random_uuid(), "description" varchar(255) not null, "value" int not null, "kind" text check ("kind" in ('deposit', 'withdraw')) not null, "wallet_id" uuid not null, "transaction_date" timestamptz not null, "user_id" uuid not null, "created_at" timestamptz not null, "updated_at" timestamptz not null, "discarded_at" timestamptz null, constraint "transactions_pkey" primary key ("id"));`);

    this.addSql(`alter table "my_finance_dev"."wallets" add constraint "wallets_owner_id_foreign" foreign key ("owner_id") references "my_finance_dev"."users" ("id") on update cascade;`);

    this.addSql(`alter table "my_finance_dev"."users" add constraint "users_main_user_wallet_id_foreign" foreign key ("main_user_wallet_id") references "my_finance_dev"."user_wallets" ("id") on update cascade on delete set null;`);

    this.addSql(`alter table "my_finance_dev"."user_wallets" add constraint "user_wallets_user_id_foreign" foreign key ("user_id") references "my_finance_dev"."users" ("id") on update cascade;`);
    this.addSql(`alter table "my_finance_dev"."user_wallets" add constraint "user_wallets_wallet_id_foreign" foreign key ("wallet_id") references "my_finance_dev"."wallets" ("id") on update cascade;`);

    this.addSql(`alter table "my_finance_dev"."transactions" add constraint "transactions_wallet_id_foreign" foreign key ("wallet_id") references "my_finance_dev"."wallets" ("id") on update cascade;`);
    this.addSql(`alter table "my_finance_dev"."transactions" add constraint "transactions_user_id_foreign" foreign key ("user_id") references "my_finance_dev"."users" ("id") on update cascade;`);
  }

  override async down(): Promise<void> {
    this.addSql(`alter table "my_finance_dev"."user_wallets" drop constraint "user_wallets_wallet_id_foreign";`);

    this.addSql(`alter table "my_finance_dev"."transactions" drop constraint "transactions_wallet_id_foreign";`);

    this.addSql(`alter table "my_finance_dev"."wallets" drop constraint "wallets_owner_id_foreign";`);

    this.addSql(`alter table "my_finance_dev"."user_wallets" drop constraint "user_wallets_user_id_foreign";`);

    this.addSql(`alter table "my_finance_dev"."transactions" drop constraint "transactions_user_id_foreign";`);

    this.addSql(`alter table "my_finance_dev"."users" drop constraint "users_main_user_wallet_id_foreign";`);

    this.addSql(`drop table if exists "my_finance_dev"."wallets" cascade;`);

    this.addSql(`drop table if exists "my_finance_dev"."users" cascade;`);

    this.addSql(`drop table if exists "my_finance_dev"."user_wallets" cascade;`);

    this.addSql(`drop table if exists "my_finance_dev"."transactions" cascade;`);

    this.addSql(`drop schema if exists "my_finance_dev";`);
  }

}
