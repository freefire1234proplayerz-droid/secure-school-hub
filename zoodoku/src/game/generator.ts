import { createRandom } from './random'
import { solvePuzzle } from './solver'
import type { Cell, Difficulty, GenerateOptions, Puzzle } from './types'
import { areAdjacent, cellKey, validatePlacements } from './validation'

const DEFAULT_SIZE_BY_DIFFICULTY: Record<Difficulty, number> = {
  normal: 6,
  hard: 8,
  ultra: 10,
}

export function generatePuzzle(options: GenerateOptions = {}): Puzzle {
  const difficulty = options.difficulty ?? 'normal'
  const size = options.size ?? DEFAULT_SIZE_BY_DIFFICULTY[difficulty]
  const maxAttempts = options.maxAttempts ?? 250
  const random = createRandom(options.seed)

  for (let attempt = 0; attempt < maxAttempts; attempt += 1) {
    const solution = generateSolution(size, random)
    const regions = growRegions(size, solution, random)
    const puzzle = { size, regions, solution }

    if (
      validatePlacements(puzzle, solution, true).isValid &&
      solvePuzzle(puzzle, { maxSolutions: 2 }).isUnique
    ) {
      return puzzle
    }
  }

  throw new Error(`Could not generate a unique ${size}x${size} puzzle.`)
}

export function generateSolution(size: number, random = createRandom()): Cell[] {
  const rows = Array.from({ length: size }, (_, row) => row)

  for (let attempt = 0; attempt < 500; attempt += 1) {
    const columns = random.shuffle(rows)
    const solution = columns.map((col, row) => ({ row, col }))

    const isLegal = solution.every((cell, index) =>
      solution
        .slice(index + 1)
        .every(
          (other) =>
            cell.row !== other.row &&
            cell.col !== other.col &&
            !areAdjacent(cell, other),
        ),
    )

    if (isLegal) {
      return solution
    }
  }

  throw new Error(`Could not place ${size} non-touching animals.`)
}

export function growRegions(size: number, solution: Cell[], random = createRandom()) {
  const regions = Array.from({ length: size }, () => Array(size).fill(-1) as number[])
  const solutionCells = new Set(solution.map(cellKey))

  solution.forEach((cell, regionId) => {
    regions[cell.row][cell.col] = regionId
  })

  let unassignedCount = size * size - solution.length

  while (unassignedCount > 0) {
    const frontier = random.shuffle(getFrontier(regions, solutionCells))

    if (frontier.length === 0) {
      throw new Error('Region growth stalled before every cell was assigned.')
    }

    const next = frontier[0]
    regions[next.cell.row][next.cell.col] = next.regionId
    unassignedCount -= 1
  }

  return regions
}

function getFrontier(regions: number[][], solutionCells: Set<string>) {
  const size = regions.length
  const frontier: { cell: Cell; regionId: number }[] = []
  const seen = new Set<string>()

  for (let row = 0; row < size; row += 1) {
    for (let col = 0; col < size; col += 1) {
      const regionId = regions[row][col]
      if (regionId === -1) {
        continue
      }

      for (const neighbor of orthogonalNeighbors({ row, col }, size)) {
        const key = cellKey(neighbor)
        if (regions[neighbor.row][neighbor.col] === -1 && !solutionCells.has(key)) {
          const frontierKey = `${key}:${regionId}`
          if (!seen.has(frontierKey)) {
            frontier.push({ cell: neighbor, regionId })
            seen.add(frontierKey)
          }
        }
      }
    }
  }

  return frontier
}

function orthogonalNeighbors(cell: Cell, size: number) {
  return [
    { row: cell.row - 1, col: cell.col },
    { row: cell.row + 1, col: cell.col },
    { row: cell.row, col: cell.col - 1 },
    { row: cell.row, col: cell.col + 1 },
  ].filter((candidate) => {
    return (
      candidate.row >= 0 &&
      candidate.row < size &&
      candidate.col >= 0 &&
      candidate.col < size
    )
  })
}
