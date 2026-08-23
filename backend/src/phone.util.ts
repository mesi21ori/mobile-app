import { BadRequestException } from '@nestjs/common';

const LOCAL = /^0[79]\d{8}$/;
const INTL = /^\+251[79]\d{8}$/;

/** Store and compare phones as 0XXXXXXXXX. */
export function normalizeEthPhone(phone: string): string {
  const s = phone.trim();
  if (INTL.test(s)) return `0${s.slice(4)}`;
  return s;
}

export function ethPhoneLookupValues(phone: string): string[] {
  const local = normalizeEthPhone(phone);
  return local.startsWith('0') ? [local, `+251${local.slice(1)}`] : [local];
}

export function assertEthPhone(phone?: string, required = false): string | undefined {
  const s = phone?.trim() ?? '';
  if (!s) {
    if (required) throw new BadRequestException('ስልክ ያስፈልጋል');
    return undefined;
  }
  if (!LOCAL.test(s) && !INTL.test(s)) {
    throw new BadRequestException('0975989898 ወይም +251975989898');
  }
  return normalizeEthPhone(s);
}
