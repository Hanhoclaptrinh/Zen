import { ForbiddenException, Injectable } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import { CreateBudgetDto } from './dto/create-budget.dto';
import { NotificationService } from 'src/notification/notification.service';
import { CategoryType } from '@prisma/client';

@Injectable()
export class BudgetsService {
  constructor(private prisma: PrismaService, private notificationService: NotificationService) {}

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

  async checkBudgetExceeded(userId: number, categoryId: number) {
    // tim budget cua user (uu tien category cu the, neu khong co thi lay budget chung)
    const budgets = await this.prisma.budget.findMany({
      where: {
        userId,
        OR: [{ categoryId }, { categoryId: null }],
      },
    });

    if (budgets.length === 0) return;

    // tinh tong chi tieu trong thang hien tai
    const startOfMonth = new Date();
    startOfMonth.setDate(1);
    startOfMonth.setHours(0, 0, 0, 0);

    for (const budget of budgets) {
      const totalExpense = await this.prisma.transaction.aggregate({
        where: {
          userId,
          type: 'expense',
          transactionDate: { gte: startOfMonth },
          // neu budget co categoryId thi chi tinh cho category do, 
          // neu khong (budget chung) thi tinh tat ca chi tieu
          ...(budget.categoryId ? { categoryId: budget.categoryId } : {}),
        },
        _sum: { amount: true },
      });

      const spent = totalExpense._sum.amount?.toNumber() || 0;
      const limit = budget.amountLimit.toNumber();

      if (spent > limit) {
        await this.notificationService.sendToUser(userId, {
          title: 'What the f*ck bro?',
          body: `Trong tháng này đã chi ${spent.toLocaleString('vi-VN')}đ á?\nChi cho cl gì thế này đại gia? So cool baby\nVượt quá hạn mức ${limit.toLocaleString('vi-VN')}đ${budget.categoryId ? ' cho danh mục này rồi' : ''}.`,
          data: {
            screen: 'budget_detail',
            budgetId: budget.id.toString(),
          },
        });
      } else if (spent > limit * 0.8) {
        await this.notificationService.sendToUser(userId, {
          title: 'Damn Shiettttt',
          body: `Tháng này chi ${spent.toLocaleString('vi-VN')}đ á? For real baby? (quá 80% hạn mức ${limit.toLocaleString('vi-VN')}đ rồi)!\nCân đối lại chi tiêu đi sĩ vương!`,
          data: {
            screen: 'budget_detail',
            budgetId: budget.id.toString(),
          },
        });
      }
    }
  }
}
