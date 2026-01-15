import { ForbiddenException, Injectable } from '@nestjs/common';
import { CategoryType } from '@prisma/client';
import { PrismaService } from 'src/prisma/prisma.service';
import { CreateBudgetDto } from './dto/create-budget.dto';

@Injectable()
export class BudgetsService {
  constructor(private prisma: PrismaService) {}

  async findAll(userId: number) {
    return this.prisma.budget.findMany({
      where: { userId },
      include: { category: true },
    });
  }

  async create(dto: CreateBudgetDto, userId: number) {
    // if category is provided, check ownership
    if (dto.categoryId) {
      const category = await this.prisma.category.findFirst({
        where: { id: dto.categoryId, userId },
      });
      if (!category) throw new ForbiddenException('Invalid category');
    }

    return this.prisma.budget.create({
      data: {
        amountLimit: dto.amountLimit,
        period: dto.period || 'monthly',
        userId,
        categoryId: dto.categoryId,
      },
    });
  }

  async update(id: number, userId: number, dto: CreateBudgetDto) {
    const budget = await this.prisma.budget.findFirst({
      where: { id, userId },
    });

    if (!budget) throw new ForbiddenException('Budget not found');

    return this.prisma.budget.update({
      where: { id },
      data: {
        amountLimit: dto.amountLimit,
        period: dto.period || 'monthly',
        categoryId: dto.categoryId,
      },
    });
  }

  async remove(id: number, userId: number) {
    return this.prisma.budget.deleteMany({
      where: { id, userId },
    });
  }

  async checkBudgetStatus(userId: number, categoryId: number) {
    // get current month's expenses for this category and compare to budget
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    const budget = await this.prisma.budget.findFirst({
      where: {
        userId,
        OR: [{ categoryId }, { categoryId: null }],
      },
    });

    if (!budget) return null;

    const expensesTotal = await this.prisma.transaction.aggregate({
      _sum: { amount: true },
      where: {
        userId,
        type: 'expense',
        categoryId: budget.categoryId || undefined,
        transactionDate: { gte: startOfMonth },
      },
    });

    const spent = Number(expensesTotal._sum.amount ?? 0);
    const limit = Number(budget.amountLimit);

    return {
      limit,
      spent,
      exceeded: spent > limit,
      remaining: limit - spent,
    };
  }
}
