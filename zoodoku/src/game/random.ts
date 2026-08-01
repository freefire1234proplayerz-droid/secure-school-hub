export type Random = {
  next: () => number
  int: (maxExclusive: number) => number
  shuffle: <T>(items: T[]) => T[]
}

export function createRandom(seed = Date.now()): Random {
  let state = seed >>> 0

  const next = () => {
    state += 0x6d2b79f5
    let value = state
    value = Math.imul(value ^ (value >>> 15), value | 1)
    value ^= value + Math.imul(value ^ (value >>> 7), value | 61)
    return ((value ^ (value >>> 14)) >>> 0) / 4294967296
  }

  return {
    next,
    int(maxExclusive) {
      return Math.floor(next() * maxExclusive)
    },
    shuffle(items) {
      const shuffled = [...items]
      for (let index = shuffled.length - 1; index > 0; index -= 1) {
        const swapIndex = Math.floor(next() * (index + 1))
        ;[shuffled[index], shuffled[swapIndex]] = [
          shuffled[swapIndex],
          shuffled[index],
        ]
      }
      return shuffled
    },
  }
}
