import { IsMongoId } from "class-validator";

export class ParamIdDto {
  
  @IsMongoId({ message: 'O id deve ser hexadecimal e conter 24 caracteres' })
  id: string;
}