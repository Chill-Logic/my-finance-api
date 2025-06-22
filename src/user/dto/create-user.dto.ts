import { User } from "@prisma/client";

export class CreateUserDto implements Omit<User, 'id' | 'main_user_wallet_id' | 'created_at' | 'updated_at' | 'discarded_at'> {
  name: string;
  email: string;
  password: string;
}