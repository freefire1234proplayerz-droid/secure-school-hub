import type { Cell, Placement, Puzzle } from './types'
import { areAdjacent, getRegionCount, getRegionId } from './validation'

export type SolveOptions = {
  maxSolutions?: number
}

export type SolveResult = {
  solutions: Placement[][]
  isUnique: boolean
}

export function solvePuzzle(
  puzzle: Puzzle,
  options: SolveOptions = {},
): SolveResult {
  const maxSolutions = options.maxSolutions ?? 2
  const candidatesByRegion = buildCandidatesByRegion(puzzle)
  const orderedRegions = candidatesByRegion
    .map((candidates, regionId) => ({ regionId, candidates }))
    .sort((a, b) => a.candidates.length - b.candidates.length)

  const solutions: Placement[][] = []
  const usedRows = new Set<number>()
  const usedColumns = new Set<number>()
  const placements: Placement[] = []

  function search(regionIndex: number) {
    if (solutions.length >= maxSolutions) {
      return
    }

    if (regionIndex === orderedRegions.length) {
      solutions.push([...placements].sort((a, b) => a.row - b.row))
      return
    }

    const { candidates } = orderedRegions[regionIndex]
    for (const candidate of candidates) {
      if (
        usedRows.has(candidate.row) ||
        usedColumns.has(candidate.col) ||
        placements.some((placement) => areAdjacent(placement, candidate))
      ) {
        continue
      }

      placements.push(candidate)
      usedRows.add(candidate.row)
      usedColumns.add(candidate.col)
      search(regionIndex + 1)
      placements.pop()
      usedRows.delete(candidate.row)
      usedColumns.delete(candidate.col)
    }
  }

  search(0)

  return {
    solutions,
    isUnique: solutions.length === 1,
  }
}

export function countSolutions(puzzle: Puzzle, maxSolutions = 2) {
  return solvePuzzle(puzzle, { maxSolutions }).solutions.length
}

function buildCandidatesByRegion(puzzle: Puzzle): Cell[][] {
  const regionCount = getRegionCount(puzzle)
  const candidatesByRegion = Array.from({ length: regionCount }, () => [] as Cell[])

  for (let row = 0; row < puzzle.size; row += 1) {
    for (let col = 0; col < puzzle.size; col += 1) {
      const regionId = getRegionId(puzzle, { row, col })
      candidatesByRegion[regionId].push({ row, col })
    }
  }

  return candidatesByRegion
}
