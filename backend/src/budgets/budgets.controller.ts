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
import { BudgetsService } from './budgets.service';
import { CreateBudgetDto } from './dto/create-budget.dto';
import { JwtAuthGuard } from 'src/auth/jwt-auth.guard';
import type { AuthRequest } from 'src/common/types/auth-request';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

@ApiTags('Budgets')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('budgets')
export class BudgetsController {
  constructor(private readonly budgetsService: BudgetsService) {}

  @Get()
  findAll(@Req() req: AuthRequest) {
    return this.budgetsService.findAll(req.user.id);
  }

  @Post()
  create(@Body() dto: CreateBudgetDto, @Req() req: AuthRequest) {
    return this.budgetsService.create(dto, req.user.id);
  }

  @Put(':id')
  update(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: CreateBudgetDto,
    @Req() req: AuthRequest,
  ) {
    return this.budgetsService.update(id, req.user.id, dto);
  }

  @Delete(':id')
  remove(@Param('id', ParseIntPipe) id: number, @Req() req: AuthRequest) {
    return this.budgetsService.remove(id, req.user.id);
  }

  @Get('check/:categoryId')
  checkStatus(
    @Param('categoryId', ParseIntPipe) categoryId: number,
    @Req() req: AuthRequest,
  ) {
    return this.budgetsService.checkBudgetStatus(req.user.id, categoryId);
  }
}
