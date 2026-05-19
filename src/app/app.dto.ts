import { IsUUID } from "class-validator";

export class ParamIdDto {
  
  @IsUUID('4', { message: 'O id deve ser um UUID válido' })
  id: string;
}