import { Controller, Post, Body } from '@nestjs/common';
import { AuthService } from './auth.service';
import { SignInDto } from './dto/sign-in.dto';
import { SignUpDto } from './dto/sign-up.dto';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('signup')
  async signup(@Body() dto: SignUpDto) {
    await this.authService.signup(dto);
    return { message: 'Usuário criado com sucesso' };
  }

  @Post('signin')
  async signin(@Body() dto: SignInDto) {
    return this.authService.signin(dto);
  }
}