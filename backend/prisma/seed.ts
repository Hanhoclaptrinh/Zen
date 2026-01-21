import { PrismaClient, CategoryType } from '@prisma/client';

const prisma = new PrismaClient();

const categories = [
  // danh muc chi tieu
  { name: 'Ăn uống', type: CategoryType.expense },
  { name: 'Di chuyển', type: CategoryType.expense },
  { name: 'Mua sắm', type: CategoryType.expense },
  { name: 'Giải trí', type: CategoryType.expense },
  { name: 'Học tập', type: CategoryType.expense },
  { name: 'Sức khỏe', type: CategoryType.expense },
  { name: 'Tiền điện', type: CategoryType.expense },
  { name: 'Tiền nước', type: CategoryType.expense },
  { name: 'Tiền mạng', type: CategoryType.expense },
  { name: 'Tiền thuê nhà', type: CategoryType.expense },
  { name: 'Quà tặng', type: CategoryType.expense },
  { name: 'Làm đẹp', type: CategoryType.expense },
  { name: 'Đầu tư', type: CategoryType.expense },
  { name: 'Khác (Chi)', type: CategoryType.expense },

  // danh muc thu
  { name: 'Lương', type: CategoryType.income },
  { name: 'Thưởng', type: CategoryType.income },
  { name: 'Tiền lãi', type: CategoryType.income },
  { name: 'Quà biếu', type: CategoryType.income },
  { name: 'Bán hàng', type: CategoryType.income },
  { name: 'Khác (Thu)', type: CategoryType.income },
];

async function main() {
  console.log('Start seeding standard categories...');
  
  for (const cat of categories) {
    await prisma.category.upsert({
      where: { 
        id: -1
      },
      update: {},
      create: {
        name: cat.name,
        type: cat.type,
        userId: null,
      },
    });
  }

  for (const cat of categories) {
    const existing = await prisma.category.findFirst({
      where: {
        name: cat.name,
        type: cat.type,
        userId: null,
      },
    });

    if (!existing) {
      await prisma.category.create({
        data: {
          name: cat.name,
          type: cat.type,
          userId: null,
        },
      });
      console.log(`Created category: ${cat.name}`);
    } else {
      console.log(`Category already exists: ${cat.name}`);
    }
  }

  console.log('Seeding finished.');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
