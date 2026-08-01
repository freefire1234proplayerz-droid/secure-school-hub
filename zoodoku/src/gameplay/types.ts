import type { Cell } from '../game'

export type BoardSnapshot = {
  placements: Cell[]
  marks: Cell[]
}

export type CellStatus = {
  hasAnimal: boolean
  hasMark: boolean
  isConflict: boolean
  isInvalidTarget: boolean
  isSelected: boolean
  isSolvedRegion: boolean
}
