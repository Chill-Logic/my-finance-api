import { Injectable } from '@nestjs/common';
import { CreateTransactionDto } from './dto/create-transaction.dto';
import { UpdateTransactionDto } from './dto/update-transaction.dto';
import { DatabaseService } from '../database/database.service';

@Injectable()
export class TransactionService {
  constructor(
    private readonly databaseService: DatabaseService
  ) {}

  
  create(createTransactionDto: CreateTransactionDto) {
    return this.databaseService.transaction.create({
      data: createTransactionDto,
    });
  }

  findAll() {
    return this.databaseService.transaction.findMany();
  }

  findOne(id: string) {
    return this.databaseService.transaction.findUnique({
      where: { id }
    });
  }

  update(id: string, updateTransactionDto: UpdateTransactionDto) {
    return this.databaseService.transaction.update({
      where: { id },
      data: updateTransactionDto,
    });
  }

  remove(id: string) {
    return this.databaseService.transaction.delete({
      where: { id },
    });
  }
}
