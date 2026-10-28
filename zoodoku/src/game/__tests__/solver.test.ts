import { describe, expect, it } from 'vitest'
import { solvePuzzle } from '../solver'
import type { Puzzle } from '../types'

const uniquePuzzle: Puzzle = {
  size: 4,
  regions: [
    [0, 0, 0, 1],
    [2, 0, 1, 1],
    [2, 2, 1, 3],
    [2, 3, 3, 3],
  ],
  solution: [
    { row: 0, col: 1 },
    { row: 1, col: 3 },
    { row: 2, col: 0 },
    { row: 3, col: 2 },
  ],
}

const ambiguousPuzzle: Puzzle = {
  size: 4,
  regions: [
    [0, 0, 1, 1],
    [0, 0, 1, 1],
    [2, 2, 3, 3],
    [2, 2, 3, 3],
  ],
  solution: [],
}

describe('solvePuzzle', () => {
  it('finds the single solution for a constrained puzzle', () => {
    const result = solvePuzzle(uniquePuzzle)

    expect(result.isUnique).toBe(true)
    expect(result.solutions[0]).toEqual(uniquePuzzle.solution)
  })

  it('stops after two solutions when a puzzle is ambiguous', () => {
    const result = solvePuzzle(ambiguousPuzzle)

    expect(result.isUnique).toBe(false)
    expect(result.solutions).toHaveLength(2)
  })
})
