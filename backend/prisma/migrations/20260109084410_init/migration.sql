-- AlterTable
ALTER TABLE `User` ADD COLUMN `resetCode` VARCHAR(191) NULL,
    ADD COLUMN `resetCodeExpires` DATETIME(3) NULL;
