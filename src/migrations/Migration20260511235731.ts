import { Migration } from '@mikro-orm/migrations';

export class Migration20260511235731 extends Migration {

  override async up(): Promise<void> {
    const schemaName = this.getSchemaName();

    this.addSql(`create schema if not exists "${schemaName}";`);
    this.addSql(`create table "${schemaName}"."wallets" ("id" uuid not null default gen_random_uuid(), "name" varchar(255) not null, "owner_id" uuid not null, "created_at" timestamptz not null, "updated_at" timestamptz not null, "discarded_at" timestamptz null, constraint "wallets_pkey" primary key ("id"));`);

    this.addSql(`create table "${schemaName}"."users" ("id" uuid not null default gen_random_uuid(), "email" varchar(255) not null, "name" varchar(255) not null, "password" varchar(255) not null, "main_user_wallet_id" uuid null, "created_at" timestamptz not null, "updated_at" timestamptz not null, "discarded_at" timestamptz null, constraint "users_pkey" primary key ("id"));`);
    this.addSql(`alter table "${schemaName}"."users" add constraint "users_email_unique" unique ("email");`);

    this.addSql(`create table "${schemaName}"."user_wallets" ("id" uuid not null default gen_random_uuid(), "user_id" uuid not null, "wallet_id" uuid not null, "accepted" boolean not null default false, "created_at" timestamptz not null, "updated_at" timestamptz not null, "discarded_at" timestamptz null, constraint "user_wallets_pkey" primary key ("id"));`);

    this.addSql(`create table "${schemaName}"."transactions" ("id" uuid not null default gen_random_uuid(), "description" varchar(255) not null, "value" int not null, "kind" text check ("kind" in ('deposit', 'withdraw')) not null, "wallet_id" uuid not null, "transaction_date" timestamptz not null, "user_id" uuid not null, "created_at" timestamptz not null, "updated_at" timestamptz not null, "discarded_at" timestamptz null, constraint "transactions_pkey" primary key ("id"));`);

    this.addSql(`alter table "${schemaName}"."wallets" add constraint "wallets_owner_id_foreign" foreign key ("owner_id") references "${schemaName}"."users" ("id") on update cascade;`);

    this.addSql(`alter table "${schemaName}"."users" add constraint "users_main_user_wallet_id_foreign" foreign key ("main_user_wallet_id") references "${schemaName}"."user_wallets" ("id") on update cascade on delete set null;`);

    this.addSql(`alter table "${schemaName}"."user_wallets" add constraint "user_wallets_user_id_foreign" foreign key ("user_id") references "${schemaName}"."users" ("id") on update cascade;`);
    this.addSql(`alter table "${schemaName}"."user_wallets" add constraint "user_wallets_wallet_id_foreign" foreign key ("wallet_id") references "${schemaName}"."wallets" ("id") on update cascade;`);

    this.addSql(`alter table "${schemaName}"."transactions" add constraint "transactions_wallet_id_foreign" foreign key ("wallet_id") references "${schemaName}"."wallets" ("id") on update cascade;`);
    this.addSql(`alter table "${schemaName}"."transactions" add constraint "transactions_user_id_foreign" foreign key ("user_id") references "${schemaName}"."users" ("id") on update cascade;`);
  }

  override async down(): Promise<void> {
    const schemaName = this.getSchemaName();

    this.addSql(`alter table "${schemaName}"."user_wallets" drop constraint "user_wallets_wallet_id_foreign";`);

    this.addSql(`alter table "${schemaName}"."transactions" drop constraint "transactions_wallet_id_foreign";`);

    this.addSql(`alter table "${schemaName}"."wallets" drop constraint "wallets_owner_id_foreign";`);

    this.addSql(`alter table "${schemaName}"."user_wallets" drop constraint "user_wallets_user_id_foreign";`);

    this.addSql(`alter table "${schemaName}"."transactions" drop constraint "transactions_user_id_foreign";`);

    this.addSql(`alter table "${schemaName}"."users" drop constraint "users_main_user_wallet_id_foreign";`);

    this.addSql(`drop table if exists "${schemaName}"."wallets" cascade;`);

    this.addSql(`drop table if exists "${schemaName}"."users" cascade;`);

    this.addSql(`drop table if exists "${schemaName}"."user_wallets" cascade;`);

    this.addSql(`drop table if exists "${schemaName}"."transactions" cascade;`);

    this.addSql(`drop schema if exists "${schemaName}";`);
  }

  private getSchemaName(): string {
    const schemaName = process.env.DB_SCHEMA;

    if (!schemaName) {
      throw new Error('DB_SCHEMA is not set');
    }

    return schemaName;
  }

}
