import { Body, Controller, Get, Param, Patch, Post, Req, UseGuards } from '@nestjs/common';
import { Role } from '@prisma/client';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { CreateUserDto, UpdateUserDto } from './dto';
import { UsersService } from './users.service';

@Controller('users')
@UseGuards(JwtAuthGuard, RolesGuard)
export class UsersController {
  constructor(private users: UsersService) {}

  @Get()
  @Roles(Role.SUPER_ADMIN)
  list() {
    return this.users.list();
  }

  @Post()
  @Roles(Role.SUPER_ADMIN)
  create(@Body() dto: CreateUserDto, @Req() req) {
    return this.users.create(dto, req.user.role);
  }

  @Patch(':id')
  @Roles(Role.SUPER_ADMIN)
  update(@Param('id') id: string, @Body() dto: UpdateUserDto, @Req() req) {
    return this.users.update(+id, dto, req.user.role);
  }
}
