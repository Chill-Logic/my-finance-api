import { Controller, Post, Body, HttpCode } from '@nestjs/common';
import { AuthService } from './auth.service';
import { SignInDto } from './dto/sign-in.dto';
import { SignUpDto } from './dto/sign-up.dto';
import { Public } from '../../decorators/public.decorator';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Public()
  @Post('sign-up')
  async signup(@Body() dto: SignUpDto) {
    await this.authService.signup(dto);
    return { message: 'Usuário criado com sucesso' };
  }

  @Public()
  @Post('sign-in')
  @HttpCode(200)
  async signin(@Body() dto: SignInDto) {
    return this.authService.signin(dto); 
  }
}