import { Wallet } from "@prisma/client";
import { IsString } from "class-validator";

export class CreateWalletDto implements Omit<Wallet, 'id' | 'owner_id' | 'created_at' | 'updated_at' | 'discarded_at'> {

  @IsString()
  name: string;
}