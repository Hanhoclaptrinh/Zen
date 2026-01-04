import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Post,
  Put,
  Req,
  UseGuards,
} from '@nestjs/common';
import { TransactionsService } from './transactions.service';
import type { AuthRequest } from 'src/common/types/auth-request';
import { CreateTransactionDto } from './dto/create-transaction.dto';
import { JwtAuthGuard } from 'src/auth/jwt-auth.guard';

@UseGuards(JwtAuthGuard)
@Controller('transactions')
export class TransactionsController {
  constructor(private readonly transactionsService: TransactionsService) {}

  @Get()
  async findAll(@Req() req: AuthRequest) {
    return this.transactionsService.findAll(req.user.id);
  }

  @Post()
  async create(@Body() dto: CreateTransactionDto, @Req() req: AuthRequest) {
    return this.transactionsService.create(dto, req.user.id);
  }

  @Put(':id')
  async update(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: CreateTransactionDto,
    @Req() req: AuthRequest,
  ) {
    return this.transactionsService.update(id, req.user.id, dto);
  }

  @Delete(':id')
  async remove(@Param('id', ParseIntPipe) id: number, @Req() req: AuthRequest) {
    return this.transactionsService.remove(id, req.user.id);
  }
}
