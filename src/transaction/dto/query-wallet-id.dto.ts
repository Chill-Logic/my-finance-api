import { Type } from "class-transformer";
import { IsDate, IsMongoId, IsOptional } from "class-validator";

export class QueryWalletIdDto {
  
  @IsMongoId({ message: 'O ID deve ser um ID Mongo válido' })
  wallet_id: string;

  @Type(() => Date)
  @IsDate()
  @IsOptional()
  start_date: Date;

  @Type(() => Date)
  @IsDate()
  @IsOptional()
  end_date: Date;
}