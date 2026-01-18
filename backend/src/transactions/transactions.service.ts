import { ForbiddenException, Injectable } from '@nestjs/common';
import { CategoryType } from '@prisma/client';
import { PrismaService } from 'src/prisma/prisma.service';
import { CreateTransactionDto } from './dto/create-transaction.dto';

@Injectable()
export class TransactionsService {
  constructor(private prisma: PrismaService) {}

  async findAll(userId: number) {
    return this.prisma.transaction.findMany({
      where: { userId },
      orderBy: { transactionDate: 'desc' },
      include: { 
        category: true,
        splitDetails: true,
      },
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

    if (dto.isSplit && (!dto.splitDetails || dto.splitDetails.length === 0)) {
      throw new ForbiddenException('Split details required');
    }

    return this.prisma.transaction.create({
      data: {
        amount: dto.amount,
        type: dto.type,
        note: dto.note,
        transactionDate: new Date(dto.transactionDate),
        isSplit: dto.isSplit || false,
        imageUrl: dto.imageUrl,
        userId,
        categoryId: dto.categoryId,
        splitDetails: dto.isSplit && dto.splitDetails ? {
          create: dto.splitDetails.map(split => ({
            name: split.name,
            amount: split.amount,
            isPaid: split.isPaid ?? false,
          })),
        } : undefined,
      },
      include: {
        splitDetails: true,
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

    if (dto.isSplit && (!dto.splitDetails || dto.splitDetails.length === 0)) {
      throw new ForbiddenException('Split details required');
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

    // update transaction and handle splitDetails (delete old, create new if isSplit is true)
    return this.prisma.$transaction(async (tx) => {
      await tx.splitDetail.deleteMany({
        where: { transactionId: id },
      });

      return tx.transaction.update({
        where: { id },
        data: {
          amount: dto.amount,
          type: dto.type,
          note: dto.note,
          transactionDate: new Date(dto.transactionDate),
          isSplit: dto.isSplit || false,
          imageUrl: dto.imageUrl,
          categoryId: dto.categoryId,
          splitDetails: dto.isSplit && dto.splitDetails ? {
            create: dto.splitDetails.map(split => ({
              name: split.name,
              amount: split.amount,
              isPaid: split.isPaid ?? false,
            })),
          } : undefined,
        },
        include: {
          splitDetails: true,
        },
      });
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
