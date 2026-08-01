import { useEffect, useMemo, useState } from 'react'
import {
  cellKey,
  cellsEqual,
  generatePuzzle,
  getRegionId,
  validatePlacements,
  type Cell,
} from '../game'
import type { BoardSnapshot, CellStatus } from '../gameplay/types'
import { Header } from './Header'
import { PuzzleBoard } from './PuzzleBoard'
import { Toolbar } from './Toolbar'
import { Badge } from './ui/Badge'
import { Button } from './ui/Button'
import { Card } from './ui/Card'

const DIFFICULTY = 'Normal'

export function GamePage() {
  const [seed, setSeed] = useState(() => Math.floor(Math.random() * 1_000_000_000))
  const puzzle = useMemo(() => generatePuzzle({ difficulty: 'normal', seed }), [seed])
  const [placements, setPlacements] = useState<Cell[]>([])
  const [marks, setMarks] = useState<Cell[]>([])
  const [history, setHistory] = useState<BoardSnapshot[]>([])
  const [selectedKey, setSelectedKey] = useState<string | null>(null)
  const [conflictKeys, setConflictKeys] = useState<Set<string>>(() => new Set())
  const [invalidTargetKey, setInvalidTargetKey] = useState<string | null>(null)
  const [isComplete, setIsComplete] = useState(false)

  const solvedRegionIds = useMemo(() => {
    const solved = new Set<number>()

    for (const placement of placements) {
      const regionId = getRegionId(puzzle, placement)
      if (cellsEqual(placement, puzzle.solution[regionId])) {
        solved.add(regionId)
      }
    }

    return solved
  }, [placements, puzzle])

  useEffect(() => {
    setPlacements([])
    setMarks([])
    setHistory([])
    setSelectedKey(null)
    setConflictKeys(new Set())
    setInvalidTargetKey(null)
    setIsComplete(false)
  }, [puzzle])

  const snapshot = (): BoardSnapshot => ({
    placements,
    marks,
  })

  const clearFeedback = () => {
    setConflictKeys(new Set())
    setInvalidTargetKey(null)
  }

  const removeCell = (cells: Cell[], cell: Cell) =>
    cells.filter((current) => !cellsEqual(current, cell))

  const hasCell = (cells: Cell[], cell: Cell) =>
    cells.some((current) => cellsEqual(current, cell))

  const showInvalidPlacement = (cell: Cell, nextPlacements: Cell[]) => {
    const validation = validatePlacements(puzzle, nextPlacements)
    const keys = new Set(validation.issues.flatMap((issue) => issue.cells.map(cellKey)))
    const key = cellKey(cell)

    keys.add(key)
    setConflictKeys(keys)
    setInvalidTargetKey(key)

    window.setTimeout(() => {
      setConflictKeys(new Set())
      setInvalidTargetKey(null)
    }, 900)
  }

  const handlePlace = (cell: Cell) => {
    const key = cellKey(cell)
    setSelectedKey(key)

    if (hasCell(placements, cell)) {
      setHistory((current) => [...current, snapshot()])
      setPlacements((current) => removeCell(current, cell))
      setIsComplete(false)
      clearFeedback()
      return
    }

    const nextPlacements = [...placements, cell]
    const validation = validatePlacements(puzzle, nextPlacements)

    if (!validation.isValid) {
      showInvalidPlacement(cell, nextPlacements)
      return
    }

    setHistory((current) => [...current, snapshot()])
    setPlacements(nextPlacements)
    setMarks((current) => removeCell(current, cell))
    clearFeedback()

    if (validatePlacements(puzzle, nextPlacements, true).isComplete) {
      setIsComplete(true)
    }
  }

  const handleToggleMark = (cell: Cell) => {
    if (hasCell(placements, cell)) {
      return
    }

    setSelectedKey(cellKey(cell))
    setHistory((current) => [...current, snapshot()])
    setMarks((current) =>
      hasCell(current, cell) ? removeCell(current, cell) : [...current, cell],
    )
    clearFeedback()
  }

  const handleUndo = () => {
    const previous = history.at(-1)
    if (!previous) {
      return
    }

    setHistory((current) => current.slice(0, -1))
    setPlacements(previous.placements)
    setMarks(previous.marks)
    setIsComplete(false)
    clearFeedback()
  }

  const handleRestart = () => {
    setPlacements([])
    setMarks([])
    setHistory([])
    setSelectedKey(null)
    setIsComplete(false)
    clearFeedback()
  }

  const handlePlayAgain = () => {
    setSeed(Math.floor(Math.random() * 1_000_000_000))
  }

  const getCellStatus = (cell: Cell, regionId: number): CellStatus => {
    const key = cellKey(cell)

    return {
      hasAnimal: hasCell(placements, cell),
      hasMark: hasCell(marks, cell),
      isConflict: conflictKeys.has(key),
      isInvalidTarget: invalidTargetKey === key,
      isSelected: selectedKey === key,
      isSolvedRegion: solvedRegionIds.has(regionId),
    }
  }

  return (
    <main className="min-h-screen bg-[#FFFDF8] px-4 py-6 text-[#2D3436] sm:px-8 sm:py-10">
      <div className="mx-auto flex w-full max-w-[900px] flex-col items-center gap-8">
        <Header />

        <Card>
          <div className="flex flex-col gap-5">
            <div className="flex flex-wrap items-center justify-center gap-3">
              <Badge tone="primary">{DIFFICULTY}</Badge>
              <Badge>{puzzle.size} x {puzzle.size}</Badge>
              <Badge tone="accent">Random</Badge>
            </div>

            <div className="mx-auto w-full max-w-[700px]">
              <PuzzleBoard
                getCellStatus={getCellStatus}
                onPlace={handlePlace}
                onToggleMark={handleToggleMark}
                puzzle={puzzle}
              />
            </div>

            <Toolbar
              canUndo={history.length > 0}
              onRestart={handleRestart}
              onUndo={handleUndo}
            />
          </div>
        </Card>
      </div>

      {isComplete ? (
        <div
          className="fixed inset-0 z-20 flex items-center justify-center bg-[#2D3436]/20 px-4 backdrop-blur-sm"
          role="dialog"
          aria-modal="true"
          aria-labelledby="complete-title"
        >
          <div className="w-full max-w-sm rounded-[2rem] border border-[#ECE7DD] bg-white p-7 text-center shadow-[0_24px_70px_rgba(45,52,54,0.18)]">
            <h2
              id="complete-title"
              className="font-['Fredoka'] text-4xl font-bold text-[#2D3436]"
            >
              Puzzle Complete!
            </h2>
            <div className="mt-6 flex justify-center">
              <Button
                ariaLabel="Play another puzzle"
                onClick={handlePlayAgain}
                variant="primary"
              >
                Play Again
              </Button>
            </div>
          </div>
        </div>
      ) : null}
    </main>
  )
}
