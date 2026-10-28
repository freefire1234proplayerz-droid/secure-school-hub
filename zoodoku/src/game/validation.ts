import type { Cell, Placement, Puzzle, ValidationIssue, ValidationResult } from './types'

export function cellKey(cell: Cell) {
  return `${cell.row},${cell.col}`
}

export function areAdjacent(a: Cell, b: Cell) {
  return (
    Math.max(Math.abs(a.row - b.row), Math.abs(a.col - b.col)) === 1
  )
}

export function cellsEqual(a: Cell, b: Cell) {
  return a.row === b.row && a.col === b.col
}

export function getRegionId(puzzle: Puzzle, cell: Cell) {
  return puzzle.regions[cell.row]?.[cell.col]
}

export function getRegionCount(puzzle: Puzzle) {
  return new Set(puzzle.regions.flat()).size
}

export function isInsideBoard(size: number, cell: Cell) {
  return cell.row >= 0 && cell.row < size && cell.col >= 0 && cell.col < size
}

export function validatePuzzleShape(puzzle: Puzzle): ValidationIssue[] {
  const issues: ValidationIssue[] = []

  if (puzzle.regions.length !== puzzle.size) {
    issues.push({
      type: 'invalid-region-map',
      cells: [],
      message: 'Region map must have one row per board row.',
    })
  }

  puzzle.regions.forEach((row, rowIndex) => {
    if (row.length !== puzzle.size) {
      issues.push({
        type: 'invalid-region-map',
        cells: [{ row: rowIndex, col: 0 }],
        message: 'Every region row must match the board size.',
      })
    }
  })

  return issues
}

export function validatePlacements(
  puzzle: Puzzle,
  placements: Placement[],
  requireComplete = false,
): ValidationResult {
  const issues = validatePuzzleShape(puzzle)
  const seenCells = new Map<string, Placement>()
  const seenRows = new Map<number, Placement>()
  const seenColumns = new Map<number, Placement>()
  const seenRegions = new Map<number, Placement>()

  for (const placement of placements) {
    if (!isInsideBoard(puzzle.size, placement)) {
      issues.push({
        type: 'out-of-bounds',
        cells: [placement],
        message: 'Animal must be placed inside the board.',
      })
      continue
    }

    const key = cellKey(placement)
    const previousCell = seenCells.get(key)
    if (previousCell) {
      issues.push({
        type: 'duplicate-cell',
        cells: [previousCell, placement],
        message: 'A cell cannot contain more than one animal.',
      })
    }
    seenCells.set(key, placement)

    const previousRow = seenRows.get(placement.row)
    if (previousRow) {
      issues.push({
        type: 'duplicate-row',
        cells: [previousRow, placement],
        message: 'Only one animal may appear in each row.',
      })
    }
    seenRows.set(placement.row, placement)

    const previousColumn = seenColumns.get(placement.col)
    if (previousColumn) {
      issues.push({
        type: 'duplicate-column',
        cells: [previousColumn, placement],
        message: 'Only one animal may appear in each column.',
      })
    }
    seenColumns.set(placement.col, placement)

    const regionId = getRegionId(puzzle, placement)
    const previousRegion = seenRegions.get(regionId)
    if (previousRegion) {
      issues.push({
        type: 'duplicate-region',
        cells: [previousRegion, placement],
        message: 'Only one animal may appear in each region.',
      })
    }
    seenRegions.set(regionId, placement)
  }

  for (let left = 0; left < placements.length; left += 1) {
    for (let right = left + 1; right < placements.length; right += 1) {
      if (areAdjacent(placements[left], placements[right])) {
        issues.push({
          type: 'adjacent-token',
          cells: [placements[left], placements[right]],
          message: 'Animals may not touch, including diagonally.',
        })
      }
    }
  }

  const regionCount = getRegionCount(puzzle)
  const isComplete = issues.length === 0 && placements.length === regionCount

  if (requireComplete && issues.length === 0) {
    for (let regionId = 0; regionId < regionCount; regionId += 1) {
      if (!seenRegions.has(regionId)) {
        issues.push({
          type: 'missing-region',
          cells: [],
          message: `Region ${regionId + 1} needs an animal.`,
        })
      }
    }
  }

  return {
    isValid: issues.length === 0,
    isComplete,
    issues,
  }
}

export function isLegalNextPlacement(puzzle: Puzzle, placements: Placement[], cell: Cell) {
  return validatePlacements(puzzle, [...placements, cell]).isValid
}
