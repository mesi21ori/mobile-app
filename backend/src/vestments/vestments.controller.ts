import { Body, Controller, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { Role } from '@prisma/client';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { BulkIssueDto, IssueVestmentDto, ReturnVestmentDto } from './dto';
import { VestmentsService } from './vestments.service';

@Controller('vestment-loans')
@UseGuards(JwtAuthGuard, RolesGuard)
export class VestmentsController {
  constructor(private vestments: VestmentsService) {}

  @Get()
  list(
    @Query('eventId') eventId?: string,
    @Query('groupId') groupId?: string,
    @Query('memberId') memberId?: string,
    @Query('dirty') dirty?: string,
    @Query('unreturned') unreturned?: string,
  ) {
    return this.vestments.loans({
      eventId: eventId ? +eventId : undefined,
      groupId: groupId ? +groupId : undefined,
      memberId: memberId ? +memberId : undefined,
      dirty: dirty === 'true',
      unreturned: unreturned === 'true',
    });
  }

  @Post('issue')
  @Roles(Role.SUPER_ADMIN, Role.ADMIN)
  issue(@Body() dto: IssueVestmentDto) {
    return this.vestments.issue(dto);
  }

  @Post('issue-bulk')
  @Roles(Role.SUPER_ADMIN, Role.ADMIN)
  bulk(@Body() dto: BulkIssueDto) {
    return this.vestments.bulkIssue(dto);
  }

  @Post('return')
  @Roles(Role.SUPER_ADMIN, Role.ADMIN)
  returnLoan(@Body() dto: ReturnVestmentDto) {
    return this.vestments.returnLoan(dto);
  }

  @Post(':id/wash')
  @Roles(Role.SUPER_ADMIN, Role.ADMIN)
  wash(@Param('id') id: string) {
    return this.vestments.markWashed(+id);
  }
}
