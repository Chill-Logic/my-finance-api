import { Controller, Get, Post, Body, Patch, Param, Delete, HttpCode, Query, Request } from '@nestjs/common';
import { TransactionService } from './transaction.service';
import { CreateTransactionDto } from './dto/create-transaction.dto';
import { UpdateTransactionDto } from './dto/update-transaction.dto';
import { User } from '@prisma/client';
import { ParamIdDto } from '../database/dto/param-id.dto';
import { QueryWalletIdDto } from './dto/query-wallet-id.dto';

@Controller('transactions')
export class TransactionController {
  constructor(private readonly transactionService: TransactionService) {}

  @Post()
  create(@Body() createTransactionDto: CreateTransactionDto, @Request() { user }: { user: User }) {
    return this.transactionService.create(createTransactionDto, user);
  }

  @Get()
  findAll(@Query() queryDto: QueryWalletIdDto, @Request() { user }: { user: User }) {
    return this.transactionService.findAll(queryDto, user);
  }

  @Get(':id')
  findOne(@Param() { id }: ParamIdDto, @Request() { user }: { user: User }) {
    return this.transactionService.findOne(id, user);
  }

  @Patch(':id')
  update(@Param() { id }: ParamIdDto, @Body() updateTransactionDto: UpdateTransactionDto, @Request() { user }: { user: User }) {
    return this.transactionService.update(id, updateTransactionDto, user);
  }

  @Delete(':id')
  @HttpCode(204)
  async remove(@Param() { id }: ParamIdDto, @Request() { user }: { user: User }) {
    await this.transactionService.remove(id, user);
    return { message: 'Transação removida com sucesso' };
  }
}
