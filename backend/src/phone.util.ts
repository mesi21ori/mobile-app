import { BadRequestException } from '@nestjs/common';

const LOCAL = /^0[79]\d{8}$/;
const INTL = /^\+251[79]\d{8}$/;

export function assertEthPhone(phone?: string, required = false): string | undefined {
  const s = phone?.trim() ?? '';
  if (!s) {
    if (required) throw new BadRequestException('ስልክ ያስፈልጋል');
    return undefined;
  }
  if (!LOCAL.test(s) && !INTL.test(s)) {
    throw new BadRequestException('0975989898 ወይም +251975989898');
  }
  return s;
}
