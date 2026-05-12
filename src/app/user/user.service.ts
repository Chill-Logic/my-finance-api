import { ConflictException, Injectable } from '@nestjs/common';
import { CreateUserDto } from './dto/create-user.dto';
import { EntityManager } from '@mikro-orm/postgresql';
import { After } from '../../decorators/after.decorator';
import { User } from './entities/user.entity';
import { Wallet } from '../wallet/entities/wallet.entity';
import { UserWallet } from '../user-wallet/entities/user-wallet.entity';

@Injectable()
export class UserService {
  constructor(
    private readonly em: EntityManager
  ) {}
  
  @After("createUserWallet")
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
  
  private async createUserWallet({ result: currentUser }: { result: User }) {
    const wallet = this.em.create(Wallet, {
      name: 'Minha Carteira',
      owner: currentUser,
    });

    const userWallet = this.em.create(UserWallet, {
      user: currentUser,
      wallet,
      accepted: true,
    });

    currentUser.main_user_wallet = userWallet;
    await this.em.flush();
  }
}
