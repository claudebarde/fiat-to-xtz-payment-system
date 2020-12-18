export const fromXTZtoFiat = (exchangeRate: number, xtz: number): number => {
  // xtz must be in mutez
  return xtz * exchangeRate;
};

export const fromFiatToXTZ = (exchangeRate: number, fiat: number): number => {
  // returns XTZ in mutez
  return Math.ceil((fiat / exchangeRate) * 10 ** 6);
};
