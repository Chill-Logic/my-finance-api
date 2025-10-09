import { Type } from "class-transformer";
import { IsDate, IsMongoId, IsNotEmpty, IsOptional } from "class-validator";

export class QueryWalletIdDto {
  
  @IsMongoId({ message: 'O wallet_id deve ser hexadecimal e conter 24 caracteres' })
  @IsNotEmpty({ message: 'O wallet_id é obrigatório' })
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