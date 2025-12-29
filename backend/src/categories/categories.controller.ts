import { Body, Controller, Delete, Get, Param, ParseIntPipe, Post, Put, Req, UseGuards } from '@nestjs/common';
import { CategoriesService } from './categories.service';
import { CreateCategoryDto } from './dto/create-category.dto';
import { JwtAuthGuard } from 'src/auth/jwt-auth.guard';
import type { AuthRequest } from 'src/common/types/auth-request';
import { UpdateCategoryDto } from './dto/update-category.dto';

@UseGuards(JwtAuthGuard)
@Controller('categories')
export class CategoriesController {
    constructor(private readonly categoriesService: CategoriesService) { }

    @Get()
    findAll(@Req() req: AuthRequest) {
        const userId = req.user.id;
        return this.categoriesService.findAll(userId);
    }

    @Post()
    create(@Body() dto: CreateCategoryDto, @Req() req: AuthRequest) {
        const userId = req.user.id;
        return this.categoriesService.create(dto, userId);
    }

    @Put(':id')
    update(@Param('id', ParseIntPipe) id: number, @Body() dto: UpdateCategoryDto, @Req() req: AuthRequest) {
        const userId = req.user.id;
        return this.categoriesService.update(id, dto, userId);
    }

    @Delete(':id')
    remove(@Param('id', ParseIntPipe) id: number, @Req() req: AuthRequest) {
        const userId = req.user.id;
        return this.categoriesService.remove(id, userId);
    }
}
