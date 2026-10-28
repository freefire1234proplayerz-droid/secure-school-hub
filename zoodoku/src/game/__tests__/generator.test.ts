import { describe, expect, it } from 'vitest'
import { generatePuzzle } from '../generator'
import { solvePuzzle } from '../solver'
import { validatePlacements } from '../validation'

describe('generatePuzzle', () => {
  it('creates a valid uniquely solvable normal puzzle', () => {
    const puzzle = generatePuzzle({ size: 6, seed: 7, maxAttempts: 300 })
    const solved = solvePuzzle(puzzle)

    expect(puzzle.size).toBe(6)
    expect(validatePlacements(puzzle, puzzle.solution, true).isComplete).toBe(true)
    expect(solved.isUnique).toBe(true)
    expect(solved.solutions[0]).toEqual(puzzle.solution)
  })
})
