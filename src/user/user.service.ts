import { Injectable } from '@nestjs/common';
import { CreateUserDto } from './dto/create-user.dto';
import { DatabaseService } from '../database/database.service';
import { After } from '../decorators/after.decorator';
import { User } from '@prisma/client';

@Injectable()
export class UserService {
  constructor(
    private readonly databaseService: DatabaseService
  ) {}
  
  @After("createUserWallet")
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
  
  private async createUserWallet ({result: current_user}: { result: User }) {
    await this.databaseService.user.update({
      where: { id: current_user.id },
      data: {
        my_wallets: {
          create: {
            name: 'Minha Carteira',
            user_wallets: {
              create: {
                user_id: current_user.id,
                users_main_wallet: {
                  connect: { id: current_user.id }
                }
              }
            }
          }
        }
      }
    })
  }
}
