
import {
  IsString,
  MinLength,
  MaxLength,
} from 'class-validator';

export class CreateErrandDto {
  @IsString()
  @MinLength(3)
  @MaxLength(100)
  title!: string;

  @IsString()
  @MinLength(5)
  @MaxLength(1000)
  description!: string;

  @IsString()
  @MinLength(3)
  @MaxLength(250)
  pickupAddress!: string;

  @IsString()
  @MinLength(3)
  @MaxLength(250)
  dropoffAddress!: string;
}
