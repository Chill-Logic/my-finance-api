import { $Enums, Transaction } from "@prisma/client";
import { IsDate, IsDateString, IsEnum, IsHexadecimal, IsNumber, IsString, Length } from "class-validator";

export class CreateTransactionDto implements Omit<Transaction, 'id' | 'created_at' | 'updated_at' | 'discarded_at'> {

  @IsString()
  description: string;

  @IsNumber()
  value: number;

  @IsEnum($Enums.TransactionKind,{})
  kind: $Enums.TransactionKind;

  @IsString()
  @Length(24, 24, { message: 'O ID deve conter exatamente 24 caracteres' })
  @IsHexadecimal({ message: 'O ID deve conter apenas caracteres hexadecimais' })
  wallet_id: string;

  @IsDateString()
  transaction_date: Date;
}