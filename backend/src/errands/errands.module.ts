
import { Module } from '@nestjs/common';
import { ErrandsController } from './errands.controller';
import { ErrandsService } from './errands.service';

@Module({
  controllers: [ErrandsController],
  providers: [ErrandsService],
})
export class ErrandsModule {}
