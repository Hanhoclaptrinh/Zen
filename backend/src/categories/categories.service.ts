import { Injectable } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import { CreateCategoryDto } from './dto/create-category.dto';
import { UpdateCategoryDto } from './dto/update-category.dto';

@Injectable()
export class CategoriesService {
  constructor(private prisma: PrismaService) {}

  findAll(userId: number) {
    return this.prisma.category.findMany({
      where: { userId },
    });
  }

  create(dto: CreateCategoryDto, userId: number) {
    return this.prisma.category.create({
      data: {
        name: dto.name,
        type: dto.type,
        userId,
      },
    });
  }

  update(id: number, dto: UpdateCategoryDto, userId: number) {
    return this.prisma.category.update({
      where: { id, userId },
      data: dto,
    });
  }

  remove(id: number, userId: number) {
    return this.prisma.category.deleteMany({
      where: { id, userId },
    });
  }
}
