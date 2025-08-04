import { IsMongoId } from "class-validator";

export class ParamIdDto {
  
  @IsMongoId({ message: 'O ID deve ser um ID Mongo válido' })
  id: string;
}