-- AlterTable
ALTER TABLE `Transaction` ADD COLUMN `imageUrl` VARCHAR(191) NULL;

-- AlterTable
ALTER TABLE `User` ADD COLUMN `avatarUrl` VARCHAR(191) NULL,
    MODIFY `passwordHash` VARCHAR(191) NULL;
