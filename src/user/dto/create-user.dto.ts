import { User } from "@prisma/client";

export class CreateUserDto implements Pick<User, 'email' | 'name' | 'password'> {
  name: string;
  email: string;
  password: string;
}