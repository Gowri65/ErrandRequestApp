
import { IsEnum } from 'class-validator';
import { ErrandStatus } from '../../../generated/prisma/enums';

export class UpdateStatusDto {
  @IsEnum(ErrandStatus)
  status!: ErrandStatus;
}
