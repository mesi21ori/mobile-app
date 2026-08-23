import { Body, Controller, Get, Post, Query, Req, UseGuards } from '@nestjs/common';
import { Role } from '@prisma/client';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { FinanceDto, OpeningBalanceDto } from './dto';
import { FinanceService } from './finance.service';

@Controller('finance')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.SUPER_ADMIN)
export class FinanceController {
  constructor(private finance: FinanceService) {}

  @Get()
  list(@Query('eventId') eventId?: string) {
    return this.finance.list(eventId ? +eventId : undefined);
  }

  @Get('summary')
  summary(@Query('eventId') eventId?: string) {
    return this.finance.summary(eventId ? +eventId : undefined);
  }

  @Post()
  create(@Body() dto: FinanceDto, @Req() req) {
    return this.finance.create(dto, req.user.id);
  }

  @Post('opening-balance')
  setOpeningBalance(@Body() dto: OpeningBalanceDto) {
    return this.finance.setOpeningBalance(dto.amount);
  }
}
