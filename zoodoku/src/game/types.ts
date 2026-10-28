export type Cell = {
  row: number
  col: number
}

export type Puzzle = {
  size: number
  regions: number[][]
  solution: Cell[]
}

export type Placement = Cell

export type Difficulty = 'normal' | 'hard' | 'ultra'

export type ValidationIssueType =
  | 'out-of-bounds'
  | 'duplicate-cell'
  | 'duplicate-row'
  | 'duplicate-column'
  | 'duplicate-region'
  | 'adjacent-token'
  | 'missing-region'
  | 'invalid-region-map'

export type ValidationIssue = {
  type: ValidationIssueType
  cells: Cell[]
  message: string
}

export type ValidationResult = {
  isValid: boolean
  isComplete: boolean
  issues: ValidationIssue[]
}

export type GenerateOptions = {
  size?: number
  difficulty?: Difficulty
  seed?: number
  maxAttempts?: number
}
