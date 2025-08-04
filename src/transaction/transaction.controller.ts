import { Controller, Get, Post, Body, Patch, Param, Delete, HttpCode, Query, Request } from '@nestjs/common';
import { TransactionService } from './transaction.service';
import { CreateTransactionDto } from './dto/create-transaction.dto';
import { UpdateTransactionDto } from './dto/update-transaction.dto';
import { User } from '@prisma/client';

@Controller('transactions')
export class TransactionController {
  constructor(private readonly transactionService: TransactionService) {}

  @Post()
  create(@Body() createTransactionDto: CreateTransactionDto, @Request() { user }: { user: User }) {
    return this.transactionService.create(createTransactionDto, user);
  }

  @Get()
  findAll(@Query('wallet_id') wallet_id: string, @Request() { user }: { user: User }) {
    return this.transactionService.findAll(wallet_id, user);
  }

  @Get(':id')
  findOne(@Param('id') id: string, @Request() { user }: { user: User }) {
    return this.transactionService.findOne(id, user);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() updateTransactionDto: UpdateTransactionDto, @Request() { user }: { user: User }) {
    return this.transactionService.update(id, updateTransactionDto, user);
  }

  @Delete(':id')
  @HttpCode(204)
  async remove(@Param('id') id: string, @Request() { user }: { user: User }) {
    await this.transactionService.remove(id, user);
    return { message: 'Transação removida com sucesso' };
  }
}
