import { Controller, Get, Request } from '@nestjs/common';
import { UserService } from './user.service';
import { User } from '@prisma/client';

@Controller('users')
export class UserController {
  constructor(private readonly userService: UserService) {}

  @Get('me')
  findOne(@Request() { user }: { user: User }) {
    const { password, ...user_data } = user;
    return user_data;
  }
}
