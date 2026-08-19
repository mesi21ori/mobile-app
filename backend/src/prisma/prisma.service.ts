import { Injectable, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

const RETRY_CODES = new Set(['P1017', 'P1001', 'P1011', 'P2024']);

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  constructor() {
    super({ log: ['error'] });
    return this.withRetry() as unknown as PrismaService;
  }

  async onModuleInit() {
    await this.connectWithRetry();
  }

  async onModuleDestroy() {
    await this.$disconnect().catch(() => undefined);
  }

  private withRetry() {
    return this.$extends({
      query: {
        $allOperations: async ({ args, query }) => {
          let lastError: unknown;
          for (let attempt = 1; attempt <= 4; attempt++) {
            try {
              return await query(args);
            } catch (error: any) {
              lastError = error;
              if (!RETRY_CODES.has(error?.code) || attempt === 4) throw error;
              await this.$disconnect().catch(() => undefined);
              await new Promise((resolve) => setTimeout(resolve, 600 * attempt));
              await this.connectWithRetry();
            }
          }
          throw lastError;
        },
      },
    });
  }

  private async connectWithRetry() {
    let lastError: unknown;
    for (let attempt = 1; attempt <= 5; attempt++) {
      try {
        await this.$connect();
        return;
      } catch (error) {
        lastError = error;
        await new Promise((resolve) => setTimeout(resolve, 800 * attempt));
      }
    }
    throw lastError;
  }
}
