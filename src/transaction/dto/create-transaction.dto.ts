import { Transaction } from "@prisma/client";

export class CreateTransactionDto implements Omit<Transaction, 'id' | 'created_at' | 'updated_at' | 'discarded_at'> {
  description: string;
  value: number;
  kind: string;
  wallet_id: string;
  transaction_date: Date;
}