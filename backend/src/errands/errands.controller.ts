
import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';

import { ErrandsService } from './errands.service';
import { CreateErrandDto } from './dto/create-errand.dto';
import { UpdateStatusDto } from './dto/update-status.dto';

import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';

import { Role } from '../../generated/prisma/enums';

@Controller('errands')
@UseGuards(JwtAuthGuard, RolesGuard)
export class ErrandsController {
  constructor(private errandsService: ErrandsService) {}

  @Post()
  @Roles(Role.REQUESTER)
  create(@Req() req: any, @Body() dto: CreateErrandDto) {
    return this.errandsService.createErrand(req.user.id, dto);
  }

  @Get('my')
  @Roles(Role.REQUESTER)
  getMyErrands(@Req() req: any) {
    return this.errandsService.getMyErrands(req.user.id);
  }

  @Get('open')
  @Roles(Role.RUNNER)
  getOpenErrands() {
    return this.errandsService.getOpenErrands();
  }

  @Get('accepted')
  @Roles(Role.RUNNER)
  getAcceptedErrands(@Req() req: any) {
    return this.errandsService.getAcceptedErrands(req.user.id);
  }

  @Post(':id/accept')
  @Roles(Role.RUNNER)
  acceptErrand(@Req() req: any, @Param('id') id: string) {
    return this.errandsService.acceptErrand(req.user.id, id);
  }

  @Patch(':id/cancel')
  @Roles(Role.REQUESTER)
  cancelErrand(@Req() req: any, @Param('id') id: string) {
    return this.errandsService.cancelErrand(req.user.id, id);
  }

  @Patch(':id/status')
  @Roles(Role.RUNNER)
  updateStatus(
    @Req() req: any,
    @Param('id') id: string,
    @Body() dto: UpdateStatusDto,
  ) {
    return this.errandsService.updateStatus(
      req.user.id,
      id,
      dto,
    );
  }
}
