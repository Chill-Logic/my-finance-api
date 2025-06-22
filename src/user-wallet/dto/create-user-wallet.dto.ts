import { UserWallet } from "@prisma/client";

export class CreateUserWalletDto implements Omit<UserWallet, 'id' | 'user_id' | 'created_at' | 'updated_at' | 'discarded_at'> {
  wallet_id: string;
}