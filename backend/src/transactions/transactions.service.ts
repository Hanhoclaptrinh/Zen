import { ForbiddenException, Injectable } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import { CreateTransactionDto } from './dto/create-transaction.dto';

@Injectable()
export class TransactionsService {
  constructor(private prisma: PrismaService) {}

  async findAll(userId: number) {
    return this.prisma.transaction.findMany({
      where: { userId },
      orderBy: { transactionDate: 'desc' },
      include: { category: true },
    });
  }

  // create new transaction
  async create(dto: CreateTransactionDto, userId: number) {
    // check if category belongs to user
    const category = await this.prisma.category.findFirst({
      where: {
        id: dto.categoryId,
        userId,
      },
    });

    if (!category) {
      throw new ForbiddenException('Invalid category');
    }

    return this.prisma.transaction.create({
      data: {
        amount: dto.amount,
        type: dto.type,
        note: dto.note,
        transactionDate: new Date(dto.transactionDate),
        userId,
        categoryId: dto.categoryId,
      },
    });
  }

  async update(id: number, userId: number, dto: CreateTransactionDto) {
    const transaction = await this.prisma.transaction.findFirst({
      where: {
        id,
        userId,
      },
    });

    if (!transaction) {
      throw new ForbiddenException('Transaction not found or access denied');
    }

    // check category if changed
    if (dto.categoryId !== transaction.categoryId) {
      const category = await this.prisma.category.findFirst({
        where: {
          id: dto.categoryId,
          userId,
        },
      });
      if (!category) {
        throw new ForbiddenException('Invalid category');
      }
    }

    return this.prisma.transaction.update({
      where: { id },
      data: {
        amount: dto.amount,
        type: dto.type,
        note: dto.note,
        transactionDate: new Date(dto.transactionDate),
        categoryId: dto.categoryId,
      },
    });
  }

  async remove(id: number, userId: number) {
    return this.prisma.transaction.deleteMany({
      where: {
        id,
        userId,
      },
    });
  }
}
