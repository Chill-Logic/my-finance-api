import { IsEmail, IsUUID } from "class-validator";

export class CreateUserWalletDto {

  @IsEmail()
  user_email: string;

  @IsUUID('4', { message: 'O wallet_id deve ser um UUID válido' })
  wallet_id: string;
}