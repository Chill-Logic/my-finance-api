import { $Enums, Transaction } from "@prisma/client";
import { IsDateString, IsEnum, IsMongoId, IsNumber, IsString } from "class-validator";

export class CreateTransactionDto implements Omit<Transaction, 'id' | 'created_at' | 'updated_at' | 'discarded_at'> {

  @IsString()
  description: string;

  @IsNumber()
  value: number;

  @IsEnum($Enums.TransactionKind,{})
  kind: $Enums.TransactionKind;

  @IsMongoId({ message: 'O ID deve ser um ID Mongo válido' })
  wallet_id: string;

  @IsDateString()
  transaction_date: Date;
}