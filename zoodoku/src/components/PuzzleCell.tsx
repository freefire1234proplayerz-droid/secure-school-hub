import { PawPrint, X } from 'lucide-react'
import { useRef } from 'react'
import type { CellStatus } from '../gameplay/types'

type PuzzleCellProps = {
  row: number
  column: number
  regionId: number
  status: CellStatus
  onPlace: () => void
  onToggleMark: () => void
}

const REGION_COLORS = [
  '#FDE1DC',
  '#DDF4E8',
  '#FFF0BD',
  '#DDEBFF',
  '#F2E2FF',
  '#FFE0C7',
  '#DDF7F8',
  '#F7E5D1',
  '#E9F5CB',
  '#F6DDEA',
]

function getRegionColor(regionId: number) {
  return REGION_COLORS[regionId % REGION_COLORS.length]
}

export function PuzzleCell({
  row,
  column,
  regionId,
  onPlace,
  onToggleMark,
  status,
}: PuzzleCellProps) {
  const longPressTimer = useRef<number | undefined>(undefined)
  const didLongPress = useRef(false)

  const clearLongPress = () => {
    if (longPressTimer.current !== undefined) {
      window.clearTimeout(longPressTimer.current)
      longPressTimer.current = undefined
    }
  }

  const handlePointerDown = () => {
    didLongPress.current = false
    clearLongPress()
    longPressTimer.current = window.setTimeout(() => {
      didLongPress.current = true
      onToggleMark()
    }, 520)
  }

  const handlePointerEnd = () => {
    clearLongPress()
  }

  const handleClick = () => {
    if (didLongPress.current) {
      didLongPress.current = false
      return
    }

    onPlace()
  }

  const cellStateClass = [
    status.isSelected
      ? 'outline outline-3 outline-offset-2 outline-[#F2C94C]'
      : 'outline-none',
    status.isConflict
      ? 'ring-2 ring-[#EB5757]/70 shadow-[0_0_22px_rgba(235,87,87,0.3)]'
      : '',
    status.isInvalidTarget
      ? 'animate-[cell-shake_180ms_ease-in-out_0s_2] border-[#EB5757] ring-2 ring-[#EB5757]'
      : '',
    status.isSolvedRegion && !status.isConflict && !status.isInvalidTarget
      ? 'animate-[region-pulse_700ms_ease-out_1] ring-2 ring-[#6FCF97]/70'
      : '',
  ].join(' ')

  return (
    <button
      type="button"
      className={`flex aspect-square touch-manipulation items-center justify-center rounded-xl border border-white/80 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition duration-150 hover:-translate-y-0.5 hover:shadow-[0_10px_18px_rgba(45,52,54,0.08)] focus-visible:outline-3 focus-visible:outline-offset-2 focus-visible:outline-[#6FCF97] ${cellStateClass}`}
      style={{ backgroundColor: getRegionColor(regionId) }}
      aria-label={`Row ${row + 1}, column ${column + 1}, region ${regionId + 1}${
        status.hasAnimal ? ', animal placed' : status.hasMark ? ', marked unavailable' : ''
      }`}
      onClick={handleClick}
      onContextMenu={(event) => {
        event.preventDefault()
        onToggleMark()
      }}
      onPointerCancel={handlePointerEnd}
      onPointerDown={handlePointerDown}
      onPointerLeave={handlePointerEnd}
      onPointerUp={handlePointerEnd}
    >
      {status.hasAnimal ? (
        <PawPrint
          aria-hidden="true"
          className="h-[52%] w-[52%] text-[#2D3436] drop-shadow-sm"
          fill="currentColor"
          strokeWidth={1.8}
        />
      ) : null}
      {!status.hasAnimal && status.hasMark ? (
        <X
          aria-hidden="true"
          className="h-[48%] w-[48%] text-[#7B7B7B]/80"
          strokeWidth={3}
        />
      ) : null}
    </button>
  )
}
