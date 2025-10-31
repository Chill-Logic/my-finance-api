import { $Enums, Transaction } from "@prisma/client";
import { Type } from "class-transformer";
import { IsDate, IsEnum, IsMongoId, IsNumber, IsString } from "class-validator";

export class CreateTransactionDto implements Omit<Transaction, 'id' | 'user_id' | 'created_at' | 'updated_at' | 'discarded_at'> {

  @IsString()
  description: string;

  @IsNumber()
  value: number;

  @IsEnum($Enums.TransactionKind,{})
  kind: $Enums.TransactionKind;

  @IsMongoId({ message: 'O wallet_id deve ser hexadecimal e conter 24 caracteres' })
  wallet_id: string;

  @Type(() => Date)
  @IsDate()
  transaction_date: Date;
}