import { describe, expect, it } from 'vitest'
import type { Puzzle } from '../types'
import { validatePlacements } from '../validation'

const puzzle: Puzzle = {
  size: 4,
  regions: [
    [0, 0, 1, 1],
    [0, 2, 2, 1],
    [3, 2, 2, 1],
    [3, 3, 3, 1],
  ],
  solution: [
    { row: 0, col: 0 },
    { row: 1, col: 2 },
    { row: 2, col: 0 },
    { row: 3, col: 3 },
  ],
}

describe('validatePlacements', () => {
  it('allows partial boards that do not break any rules', () => {
    const result = validatePlacements(puzzle, [
      { row: 0, col: 0 },
      { row: 3, col: 3 },
    ])

    expect(result.isValid).toBe(true)
    expect(result.isComplete).toBe(false)
  })

  it('reports row, column, region, and adjacency conflicts', () => {
    const result = validatePlacements(puzzle, [
      { row: 0, col: 0 },
      { row: 0, col: 1 },
      { row: 1, col: 1 },
    ])

    expect(result.isValid).toBe(false)
    expect(result.issues.map((issue) => issue.type)).toEqual(
      expect.arrayContaining([
        'duplicate-row',
        'duplicate-column',
        'duplicate-region',
        'adjacent-token',
      ]),
    )
  })

  it('requires one animal per region when checking a solved board', () => {
    const result = validatePlacements(puzzle, [{ row: 0, col: 0 }], true)

    expect(result.isValid).toBe(false)
    expect(result.issues.some((issue) => issue.type === 'missing-region')).toBe(true)
  })
})
