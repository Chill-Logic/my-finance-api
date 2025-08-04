import { IsMongoId } from "class-validator";

export class QueryWalletIdDto {
  
  @IsMongoId({ message: 'O ID deve ser um ID Mongo válido' })
  wallet_id: string;
}