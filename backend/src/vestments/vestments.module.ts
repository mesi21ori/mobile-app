import { Module } from '@nestjs/common';
import { VestmentsController } from './vestments.controller';
import { VestmentsService } from './vestments.service';

@Module({
  controllers: [VestmentsController],
  providers: [VestmentsService],
})
export class VestmentsModule {}
