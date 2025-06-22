import { Injectable } from '@nestjs/common';
import { CreateUserDto } from './dto/create-user.dto';
import { DatabaseService } from '../database/database.service';

@Injectable()
export class UserService {
  constructor(
    private readonly databaseService: DatabaseService
  ) {}

  create(createUserDto: CreateUserDto) {
    return this.databaseService.user.create({
      data: createUserDto
    });
  }

  async findOne({ id, email}: { id?: string; email?: string }) {
    const user = await this.databaseService.user.findFirst({
      where: { id, email }
    });
    return user;
  }
}
