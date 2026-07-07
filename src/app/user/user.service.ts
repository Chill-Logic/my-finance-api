import { ConflictException, Injectable } from '@nestjs/common';
import { CreateUserDto } from './dto/create-user.dto';
import { EntityManager } from '@mikro-orm/postgresql';
import { User } from './entities/user.entity';

@Injectable()
export class UserService {
  constructor(
    private readonly em: EntityManager
  ) {}

  async create(createUserDto: CreateUserDto) {
    if (await this.em.findOne(User, { email: createUserDto.email })) {
      throw new ConflictException({
        message: 'Email já cadastrado'
      });
    }

    const user = this.em.create(User, createUserDto);
    await this.em.flush();
    return user;
  }

  async findOne({ id, email }: { id?: string; email?: string }) {
    const user = await this.em.findOne(User, {
      ...(id && { id }),
      ...(email && { email }),
    });
    return user;
  }
}
