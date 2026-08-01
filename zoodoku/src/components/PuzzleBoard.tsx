import type { Cell, Puzzle } from '../game'
import type { CellStatus } from '../gameplay/types'
import { PuzzleCell } from './PuzzleCell'

type PuzzleBoardProps = {
  getCellStatus: (cell: Cell, regionId: number) => CellStatus
  onPlace: (cell: Cell) => void
  onToggleMark: (cell: Cell) => void
  puzzle: Puzzle
}

export function PuzzleBoard({
  getCellStatus,
  onPlace,
  onToggleMark,
  puzzle,
}: PuzzleBoardProps) {
  return (
    <div
      className="aspect-square w-full rounded-[1.75rem] border border-[#ECE7DD] bg-[#FFFDF8] p-2 shadow-[inset_0_1px_0_rgba(255,255,255,0.9),0_16px_36px_rgba(45,52,54,0.08)] sm:p-3"
      aria-label={`${puzzle.size} by ${puzzle.size} Zoodoku puzzle board`}
    >
      <div
        className="grid h-full w-full gap-1.5 rounded-[1.25rem] sm:gap-2"
        style={{
          gridTemplateColumns: `repeat(${puzzle.size}, minmax(0, 1fr))`,
        }}
      >
        {puzzle.regions.map((row, rowIndex) =>
          row.map((regionId, columnIndex) => (
            <PuzzleCell
              key={`${rowIndex}-${columnIndex}`}
              row={rowIndex}
              column={columnIndex}
              regionId={regionId}
              status={getCellStatus({ row: rowIndex, col: columnIndex }, regionId)}
              onPlace={() => onPlace({ row: rowIndex, col: columnIndex })}
              onToggleMark={() => onToggleMark({ row: rowIndex, col: columnIndex })}
            />
          )),
        )}
      </div>
    </div>
  )
}
