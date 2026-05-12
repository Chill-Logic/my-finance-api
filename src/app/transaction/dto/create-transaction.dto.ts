import { TransactionKind } from "../entities/transaction.entity";
import { Type } from "class-transformer";
import { IsDate, IsEnum, IsNumber, IsString, IsUUID } from "class-validator";

export class CreateTransactionDto {

  @IsString()
  description: string;

  @IsNumber()
  value: number;

  @IsEnum(TransactionKind)
  kind: TransactionKind;

  @IsUUID('4', { message: 'O wallet_id deve ser um UUID válido' })
  wallet_id: string;

  @Type(() => Date)
  @IsDate()
  transaction_date: Date;
}