import { User } from "@prisma/client";
import { IsEmail, IsString } from "class-validator";

export class CreateUserDto implements Omit<User, 'id' | 'main_user_wallet_id' | 'created_at' | 'updated_at' | 'discarded_at'> {

  @IsString()
  name: string;

  @IsEmail()
  email: string;

  @IsString()
  password: string;
}