import { UserWallet } from "@prisma/client";
import { IsEmail, IsMongoId } from "class-validator";

export class CreateUserWalletDto implements Omit<UserWallet, 'id' | 'user_id' | 'accepted' | 'created_at' | 'updated_at' | 'discarded_at'> {

  @IsEmail()
  user_email: string;

  @IsMongoId({ message: 'O id deve ser hexadecimal e conter 24 caracteres' })
  wallet_id: string;
}