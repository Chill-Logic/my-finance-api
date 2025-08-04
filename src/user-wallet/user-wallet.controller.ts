import { Controller, Get, Post, Body, Patch, Param, Delete, Request } from '@nestjs/common';
import { UserWalletService } from './user-wallet.service';
import { CreateUserWalletDto } from './dto/create-user-wallet.dto';
// import { UpdateUserWalletDto } from './dto/update-user-wallet.dto';
import { User } from '@prisma/client';

@Controller('user-wallets')
export class UserWalletController {
  constructor(private readonly userWalletService: UserWalletService) {}

  @Post()
  async create(@Body() createUserWalletDto: CreateUserWalletDto, @Request() { user }: { user: User }) {
    await this.userWalletService.create(createUserWalletDto, user);
    return { message: "Usuário convidado com sucesso!" }
  }

  @Get()
  invites(@Request() { user }: { user: User }) {
    return this.userWalletService.findInvites(user);
  }

  @Post(':id')
  async accept(@Param('id') id: string, @Request() { user }: { user: User }) {
    await this.userWalletService.acceptInvite(id, user);
    return { message: "Convite aceito com sucesso!" }
  }

  @Post(':id')
  async reject(@Param('id') id: string, @Request() { user }: { user: User }) {
    await this.userWalletService.rejectInvite(id, user);
    return { message: "Convite rejeitado com sucesso!" }
  }

  // @Patch(':id')
  // update(@Param('id') id: string, @Body() updateUserWalletDto: UpdateUserWalletDto) {
  //   return this.userWalletService.update(+id, updateUserWalletDto);
  // }

  // @Delete(':id')
  // remove(@Param('id') id: string) {
  //   return this.userWalletService.remove(+id);
  // }
}
