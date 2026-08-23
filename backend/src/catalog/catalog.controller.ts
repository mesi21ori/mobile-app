import { Body, Controller, Delete, Get, Param, Patch, Post, Put, Req, UseGuards } from '@nestjs/common';
import { Role } from '@prisma/client';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { CatalogService } from './catalog.service';
import {
  AddGroupMembersDto,
  DepartmentDto,
  EventDto,
  GroupDto,
  MemberDto,
  SetEventParticipantsDto,
  UpdateDepartmentDto,
  UpdateEventDto,
  UpdateMemberDto,
  UpdateVestmentDto,
  VestmentDto,
} from './dto';

@Controller()
@UseGuards(JwtAuthGuard, RolesGuard)
export class CatalogController {
  constructor(private catalog: CatalogService) {}

  @Get('dashboard')
  dashboard() {
    return this.catalog.dashboard();
  }

  @Get('departments')
  departments() {
    return this.catalog.departments();
  }

  @Post('departments')
  @Roles(Role.SUPER_ADMIN, Role.ADMIN)
  createDepartment(@Body() dto: DepartmentDto) {
    return this.catalog.createDepartment(dto);
  }

  @Patch('departments/:id')
  @Roles(Role.SUPER_ADMIN, Role.ADMIN)
  updateDepartment(@Param('id') id: string, @Body() dto: UpdateDepartmentDto) {
    return this.catalog.updateDepartment(+id, dto);
  }

  @Delete('departments/:id')
  @Roles(Role.SUPER_ADMIN, Role.ADMIN)
  deleteDepartment(@Param('id') id: string) {
    return this.catalog.deleteDepartment(+id);
  }

  @Get('members')
  members() {
    return this.catalog.members();
  }

  @Post('members')
  @Roles(Role.SUPER_ADMIN, Role.ADMIN, Role.CLASS_LEADER)
  createMember(@Body() dto: MemberDto, @Req() req) {
    return this.catalog.createMember(dto, req.user);
  }

  @Patch('members/:id')
  @Roles(Role.SUPER_ADMIN, Role.ADMIN, Role.CLASS_LEADER)
  updateMember(@Param('id') id: string, @Body() dto: UpdateMemberDto, @Req() req) {
    return this.catalog.updateMember(+id, dto, req.user);
  }

  @Delete('members/:id')
  @Roles(Role.SUPER_ADMIN, Role.ADMIN, Role.CLASS_LEADER)
  deleteMember(@Param('id') id: string, @Req() req) {
    return this.catalog.deleteMember(+id, req.user);
  }

  @Get('vestments')
  vestments() {
    return this.catalog.vestments();
  }

  @Post('vestments')
  @Roles(Role.SUPER_ADMIN, Role.ADMIN)
  createVestment(@Body() dto: VestmentDto) {
    return this.catalog.createVestment(dto);
  }

  @Patch('vestments/:id')
  @Roles(Role.SUPER_ADMIN, Role.ADMIN)
  updateVestment(@Param('id') id: string, @Body() dto: UpdateVestmentDto) {
    return this.catalog.updateVestment(+id, dto);
  }

  @Delete('vestments/:id')
  @Roles(Role.SUPER_ADMIN, Role.ADMIN)
  deleteVestment(@Param('id') id: string) {
    return this.catalog.deleteVestment(+id);
  }

  @Get('events')
  events() {
    return this.catalog.events();
  }

  @Post('events')
  @Roles(Role.SUPER_ADMIN, Role.ADMIN, Role.CLASS_LEADER)
  createEvent(@Body() dto: EventDto) {
    return this.catalog.createEvent(dto);
  }

  @Patch('events/:id')
  @Roles(Role.SUPER_ADMIN, Role.ADMIN)
  updateEvent(@Param('id') id: string, @Body() dto: UpdateEventDto) {
    return this.catalog.updateEvent(+id, dto);
  }

  @Delete('events/:id')
  @Roles(Role.SUPER_ADMIN, Role.ADMIN)
  deleteEvent(@Param('id') id: string) {
    return this.catalog.deleteEvent(+id);
  }

  @Get('events/:id/participants')
  eventParticipants(@Param('id') id: string, @Req() req) {
    return this.catalog.eventParticipants(+id, req.user);
  }

  @Put('events/:id/participants')
  @Roles(Role.CLASS_LEADER)
  setEventParticipants(@Param('id') id: string, @Body() dto: SetEventParticipantsDto, @Req() req) {
    return this.catalog.setEventParticipants(+id, dto, req.user);
  }

  @Get('groups')
  groups(@Req() req) {
    return this.catalog.groups(req.user);
  }

  @Post('groups')
  @Roles(Role.SUPER_ADMIN, Role.ADMIN, Role.CLASS_LEADER)
  createGroup(@Body() dto: GroupDto, @Req() req) {
    return this.catalog.createGroup(dto, req.user);
  }

  @Patch('groups/:id')
  @Roles(Role.SUPER_ADMIN, Role.ADMIN, Role.CLASS_LEADER)
  updateGroup(@Param('id') id: string, @Body() dto: GroupDto, @Req() req) {
    return this.catalog.updateGroup(+id, dto, req.user);
  }

  @Delete('groups/:id')
  @Roles(Role.SUPER_ADMIN, Role.ADMIN, Role.CLASS_LEADER)
  deleteGroup(@Param('id') id: string, @Req() req) {
    return this.catalog.deleteGroup(+id, req.user);
  }

  @Post('groups/members')
  @Roles(Role.SUPER_ADMIN, Role.ADMIN)
  addMembers(@Body() dto: AddGroupMembersDto) {
    return this.catalog.addGroupMembers(dto);
  }

  @Get('settings')
  settings() {
    return this.catalog.settings();
  }

  @Post('settings')
  @Roles(Role.SUPER_ADMIN)
  setSetting(@Body() body: { key: string; value: string }) {
    return this.catalog.setSetting(body.key, body.value);
  }
}
