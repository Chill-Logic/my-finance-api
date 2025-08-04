import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { CreateUserWalletDto } from './dto/create-user-wallet.dto';
// import { UpdateUserWalletDto } from './dto/update-user-wallet.dto';
import { User } from '@prisma/client';
import { DatabaseService } from '../database/database.service';

@Injectable()
export class UserWalletService {
  constructor(
    private readonly databaseService: DatabaseService
  ) {}

  async create(createUserWalletDto: CreateUserWalletDto, user: User) {
    const userInvite = await this.databaseService.user.findFirst({
      where: {
        email: createUserWalletDto.user_email
      }
    })

    if (!userInvite) throw new NotFoundException({
      message: "Não foi encontrado usuário com esse e-mail"
    })

    const wallet = await this.databaseService.wallet.findUnique({
      where: {
        id: createUserWalletDto.wallet_id,
        owner_id: user.id
      }
    })

    if (!wallet) throw new NotFoundException({
      message: 'A carteira informada não foi encontrada'
    });

    const userAccess = await this.databaseService.userWallet.findFirst({
      where: {
        user_id: userInvite.id,
        wallet_id: createUserWalletDto.wallet_id
      }
    })

    if (userAccess) throw new ConflictException({
      message: "O usuário já foi convidado para essa carteira"
    })

    const createRelation = await this.databaseService.userWallet.create({
      data: {
        wallet_id: createUserWalletDto.wallet_id,
        user_id: userInvite.id
      }
    })

    return createRelation
  }

  async findInvites(user: User) {
    const invites = await this.databaseService.userWallet.findMany({
      where: {
        user_id: user.id,
        accepted: false
      },
      include: {
        user: {
          select: {
            name: true
          }
        },
        wallet: {
          include: {
            owner: {
              select: {
                name: true
              }
            }
          }
        }
      }
    })

    return invites.map(invite => ({
      id: invite.id,
      wallet_name: invite.wallet.name,
      owner_name: invite.wallet.owner.name
    }))
  }

  async acceptInvite(id: string, user: User) {
    const invite = await this.databaseService.userWallet.updateMany({
      where: {
        id,
        user_id: user.id,
        accepted: false
      },
      data: {
        accepted: true
      }
    })

    if (!invite.count) throw new NotFoundException({
      message: "Não foi possível encontrar o convite ou ele já foi aceito"
    })

    return invite
  }

  async rejectInvite (id: string, user: User) {
    const invite = await this.databaseService.userWallet.deleteMany({
      where: {
        id,
        user_id: user.id,
        accepted: false
      }
    })

    if (!invite.count) throw new NotFoundException({
      message: "Não foi possível encontrar o convite ou ele já foi aceito"
    })

    return invite
  }

  // update(id: number, updateUserWalletDto: UpdateUserWalletDto) {
  //   return `This action updates a #${id} userWallet`;
  // }

  // remove(id: number) {
  //   return `This action removes a #${id} userWallet`;
  // }
}
