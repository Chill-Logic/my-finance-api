import { UserWallet } from "@prisma/client";
import { IsBoolean, IsEmail, IsHexadecimal, IsOptional, IsString, Length } from "class-validator";

export class CreateUserWalletDto implements Omit<UserWallet, 'id' | 'user_id' | 'accepted' | 'created_at' | 'updated_at' | 'discarded_at'> {

  @IsEmail()
  user_email: string;

  @IsString()
  @Length(24, 24, { message: 'O ID deve conter exatamente 24 caracteres' })
  @IsHexadecimal({ message: 'O ID deve conter apenas caracteres hexadecimais' })
  wallet_id: string;
}