import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { CreateUserWalletDto } from './dto/create-user-wallet.dto';
import { User } from '../user/entities/user.entity';
import { EntityManager } from '@mikro-orm/postgresql';
import { Wallet } from '../wallet/entities/wallet.entity';
import { UserWallet } from './entities/user-wallet.entity';

@Injectable()
export class UserWalletService {
  constructor(
    private readonly em: EntityManager
  ) {}

  async create(createUserWalletDto: CreateUserWalletDto, user: User) {
    const userInvite = await this.em.findOne(User, {
      email: createUserWalletDto.user_email
    });

    if (!userInvite) throw new NotFoundException({
      message: "Não foi encontrado usuário com esse e-mail"
    })

    const wallet = await this.em.findOne(Wallet, {
      id: createUserWalletDto.wallet_id,
      owner: user.id
    });

    if (!wallet) throw new NotFoundException({
      message: 'A carteira informada não foi encontrada'
    });

    const userAccess = await this.em.findOne(UserWallet, {
      user: userInvite.id,
      wallet: createUserWalletDto.wallet_id
    });

    if (userAccess) throw new ConflictException({
      message: "O usuário já foi convidado para essa carteira"
    })

    const createRelation = this.em.create(UserWallet, {
      wallet: createUserWalletDto.wallet_id,
      user: userInvite.id
    });

    await this.em.flush();
    return createRelation;
  }

  async findInvites(user: User) {
    const invites = await this.em.find(UserWallet, {
      user: user.id,
      accepted: false
    }, {
      populate: ['user', 'wallet', 'wallet.owner']
    });

    return invites.map(invite => ({
      id: invite.id,
      wallet_name: invite.wallet.name,
      owner_name: invite.wallet.owner.name
    }))
  }

  async acceptInvite(id: string, user: User) {
    const invite = await this.em.findOne(UserWallet, {
      id,
      user: user.id,
      accepted: false
    });

    if (!invite) throw new NotFoundException({
      message: "Não foi possível encontrar o convite ou ele já foi aceito"
    })

    invite.accepted = true;
    await this.em.flush();
    return invite;
  }

  async rejectInvite(id: string, user: User) {
    const invite = await this.em.findOne(UserWallet, {
      id,
      user: user.id,
      accepted: false
    });

    if (!invite) throw new NotFoundException({
      message: "Não foi possível encontrar o convite ou ele já foi aceito"
    })

    await this.em.remove(invite).flush();
  }
}
