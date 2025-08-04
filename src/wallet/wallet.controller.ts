import { Controller, Get, Post, Body, Patch, Param, Delete, Request } from '@nestjs/common';
import { WalletService } from './wallet.service';
import { CreateWalletDto } from './dto/create-wallet.dto';
import { UpdateWalletDto } from './dto/update-wallet.dto';
import { User } from '@prisma/client';
import { ParamIdDto } from '../database/dto/param-id.dto';

@Controller('wallets')
export class WalletController {
  constructor(private readonly walletService: WalletService) {}

  @Get('main')
  async findMain(@Request() { user }: { user: User }) {
    return await this.walletService.findOneByUserWalletId(user.main_user_wallet_id);
  }

  @Post()
  create(@Body() createWalletDto: CreateWalletDto, @Request() { user }: { user: User }) {
    return this.walletService.create(createWalletDto, user);
  }

  @Get()
  findAll(@Request() { user }: { user: User }) {
    return this.walletService.findAll(user);
  }

  // @Get(':id')
  // findOne(@Param() { id }: ParamIdDto) {
  //   return this.walletService.findOne(id);
  // }

  @Patch(':id')
  update(@Param() { id }: ParamIdDto, @Body() updateWalletDto: UpdateWalletDto, @Request() { user }: { user: User }) {
    return this.walletService.update(id, updateWalletDto, user);
  }

  // @Delete(':id')
  // remove(@Param() { id }: ParamIdDto) {
  //   return this.walletService.remove(id);
  // }
}
