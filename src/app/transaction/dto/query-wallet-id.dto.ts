import { Type } from "class-transformer";
import { IsDate, IsUUID, IsNotEmpty, IsOptional } from "class-validator";

export class QueryWalletIdDto {
  
  @IsUUID('4', { message: 'O wallet_id deve ser um UUID válido' })
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