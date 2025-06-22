import { Injectable, UnauthorizedException } from '@nestjs/common';
import { UserService } from '../user/user.service';
import { JwtService } from '@nestjs/jwt';
import { SignInDto } from './dto/sign-in.dto';
import * as bcrypt from 'bcrypt';
import { JwtPayloadParams } from './entities/jwt-payload.params';
import { SignUpDto } from './dto/sign-up.dto';

@Injectable()
export class AuthService {
  constructor(
    private userService: UserService,
    private jwtService: JwtService
  ) {}

  async signup(dto: SignUpDto) {
    const hashedPassword = await bcrypt.hash(dto.password, 10);
    return this.userService.create({
      ...dto,
      password: hashedPassword,
    });
  }

  async validateUser(email: string, password: string): Promise<JwtPayloadParams> {
    const user = await this.userService.findOne({email});

    if (!user || !(await bcrypt.compare(password, user.password))) {
      throw new UnauthorizedException({
        message: 'Credenciais inválidas'
      });
    }

    return {id: user.id, email: user.email, name: user.name};
  }

  async signin({email, password}: SignInDto) {
    const user = await this.validateUser(email, password);
    return {
      token: this.jwtService.sign(user),
    };
  }
}