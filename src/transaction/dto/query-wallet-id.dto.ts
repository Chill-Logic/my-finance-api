import { Type } from "class-transformer";
import { IsDate, IsMongoId, IsOptional } from "class-validator";

export class QueryWalletIdDto {
  
  @IsMongoId({ message: 'O id deve ser hexadecimal e conter 24 caracteres' })
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