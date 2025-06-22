import { Wallet } from "@prisma/client";

export class CreateWalletDto implements Omit<Wallet, 'id' | 'created_at' | 'updated_at' | 'discarded_at'> {
  name: string;
  owner_id: string;
}