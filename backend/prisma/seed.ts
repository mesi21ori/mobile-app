import { PrismaClient, Role, AssetType } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  const username = process.env.SEED_ADMIN_USERNAME || 'admin';
  const password = process.env.SEED_ADMIN_PASSWORD || 'Admin@123';
  const hash = await bcrypt.hash(password, 10);

  await prisma.setting.upsert({
    where: { key: 'daily_penalty_rate' },
    create: { key: 'daily_penalty_rate', value: '10' },
    update: {},
  });

  const choir = await prisma.department.upsert({
    where: { id: 1 },
    update: {},
    create: { name: 'መዘምራን', head: 'የመዘምራን ኃላፊ' },
  });

  const teaching = await prisma.department.upsert({
    where: { id: 2 },
    update: {},
    create: { name: 'ትምህርት', head: 'የትምህርት ኃላፊ' },
  });

  await prisma.user.upsert({
    where: { username },
    update: {},
    create: {
      fullName: 'ዋና አስተዳዳሪ',
      username,
      passwordHash: hash,
      role: Role.SUPER_ADMIN,
    },
  });

  const vestments = [
    { name: 'ቃባ', totalQuantity: 40 },
    { name: 'ሞጥ', totalQuantity: 40 },
    { name: 'የካህን ልብስ', totalQuantity: 10 },
    { name: 'መስቀል ልብስ', totalQuantity: 20 },
  ];
  for (const v of vestments) {
    const exists = await prisma.vestment.findFirst({ where: { name: v.name } });
    if (!exists) {
      await prisma.vestment.create({
        data: {
          name: v.name,
          totalQuantity: v.totalQuantity,
          availableQuantity: v.totalQuantity,
        },
      });
    }
  }

  const assets = [
    { name: 'ማይክሮፎን', type: AssetType.RETURNABLE, qty: 8 },
    { name: 'ስፒከር', type: AssetType.RETURNABLE, qty: 4 },
    { name: 'ወንበር', type: AssetType.RETURNABLE, qty: 50 },
    { name: 'ወረቀት', type: AssetType.CONSUMABLE, qty: 200 },
  ];
  for (const a of assets) {
    const exists = await prisma.asset.findFirst({ where: { name: a.name } });
    if (!exists) {
      await prisma.asset.create({
        data: {
          name: a.name,
          type: a.type,
          totalQuantity: a.qty,
          availableQuantity: a.qty,
        },
      });
    }
  }

  const names = ['አበበ ከበደ', 'አልማዝ ተስፋዬ', 'ዳንኤል መኮንን', 'ሄለን ገብሩ', 'ሙሉጌታ አሸናፊ'];
  for (const fullName of names) {
    const exists = await prisma.member.findFirst({ where: { fullName } });
    if (!exists) {
      await prisma.member.create({
        data: { fullName, departmentId: choir.id, phoneNumber: '0911000000' },
      });
    }
  }

  console.log('Seed complete. Super Admin username:', username);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
