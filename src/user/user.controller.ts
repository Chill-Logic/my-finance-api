import { Controller, Get, Request } from '@nestjs/common';
import { UserService } from './user.service';
import { User } from '@prisma/client';

@Controller('user')
export class UserController {
  constructor(private readonly userService: UserService) {}

  @Get()
  findOne(@Request() req: { user: User }) {
    const { password, ...user_data } = req.user;
    return user_data;
  }
}
