import { Body, Controller, Delete, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { AssetType, Role } from '@prisma/client';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { AssetDto, CheckinDto, CheckoutDto, CheckoutManyDto, UpdateAssetDto } from './dto';
import { InventoryService } from './inventory.service';

@Controller()
@UseGuards(JwtAuthGuard, RolesGuard)
export class InventoryController {
  constructor(private inventory: InventoryService) {}

  @Get('assets')
  assets(@Query('type') type?: AssetType) {
    return this.inventory.assets(type);
  }

  @Post('assets')
  @Roles(Role.SUPER_ADMIN, Role.ADMIN)
  create(@Body() dto: AssetDto) {
    return this.inventory.createAsset(dto);
  }

  @Patch('assets/:id')
  @Roles(Role.SUPER_ADMIN, Role.ADMIN)
  updateAsset(@Param('id') id: string, @Body() dto: UpdateAssetDto) {
    return this.inventory.updateAsset(+id, dto);
  }

  @Delete('assets/:id')
  @Roles(Role.SUPER_ADMIN, Role.ADMIN)
  removeAsset(@Param('id') id: string) {
    return this.inventory.deleteAsset(+id);
  }

  @Get('asset-loans')
  loans(
    @Query('open') open?: string,
    @Query('type') type?: AssetType,
    @Query('departmentId') departmentId?: string,
  ) {
    return this.inventory.loans({
      openOnly: open === 'true',
      type,
      departmentId: departmentId ? Number(departmentId) : undefined,
    });
  }

  @Post('asset-loans/checkout')
  @Roles(Role.SUPER_ADMIN, Role.ADMIN)
  checkout(@Body() dto: CheckoutDto) {
    return this.inventory.checkout(dto);
  }

  @Post('asset-loans/checkout-many')
  @Roles(Role.SUPER_ADMIN, Role.ADMIN)
  checkoutMany(@Body() dto: CheckoutManyDto) {
    return this.inventory.checkoutMany(dto);
  }

  @Post('asset-loans/checkin')
  @Roles(Role.SUPER_ADMIN, Role.ADMIN)
  checkin(@Body() dto: CheckinDto) {
    return this.inventory.checkin(dto);
  }

  @Delete('asset-loans/:id')
  @Roles(Role.SUPER_ADMIN, Role.ADMIN)
  removeLoan(@Param('id') id: string) {
    return this.inventory.deleteLoan(+id);
  }
}
