import { ExtractJwt, Strategy } from 'passport-jwt';
import { PassportStrategy } from '@nestjs/passport';
import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtPayloadParams } from './entities/jwt-payload.params';
import { UserService } from '../user/user.service';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor( private usersService: UserService, configService: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: configService.get<string>('JWT_SECRET')
    });
  }

  async validate(payload: JwtPayloadParams) {
    const user = await this.usersService.findOne({email: payload.email});
    if (!user) throw new UnauthorizedException({message: 'Usuário não encontrado'});
    
    return user;
  }
}