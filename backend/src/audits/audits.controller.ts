import { BadRequestException, Body, Controller, Get, Param, Post, Query, Req, UseGuards } from '@nestjs/common';
import { AuditPeriod, Role } from '@prisma/client';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { CreateAuditDto } from './dto';
import { AuditsService } from './audits.service';

@Controller('audits')
@UseGuards(JwtAuthGuard, RolesGuard)
export class AuditsController {
  constructor(private audits: AuditsService) {}

  @Get()
  list() {
    return this.audits.list();
  }

  @Get('preview')
  preview(@Query('departmentId') departmentId?: string, @Query('period') period?: string) {
    const id = Number(departmentId);
    if (!Number.isInteger(id)) throw new BadRequestException('ክፍል ይምረጡ');
    const p = period === 'THREE_MONTHS' ? AuditPeriod.THREE_MONTHS : AuditPeriod.SIX_MONTHS;
    return this.audits.preview(id, p);
  }

  @Post()
  @Roles(Role.SUPER_ADMIN, Role.ADMIN)
  create(@Body() dto: CreateAuditDto, @Req() req) {
    return this.audits.create(dto, req.user.id);
  }

  @Post(':id/approve')
  @Roles(Role.SUPER_ADMIN)
  approve(@Param('id') id: string, @Req() req) {
    return this.audits.approve(+id, req.user.id);
  }
}
