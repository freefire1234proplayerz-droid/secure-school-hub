import { Lightbulb, RotateCcw, Settings, Undo2 } from 'lucide-react'
import { Button } from './ui/Button'

type ToolbarProps = {
  canUndo: boolean
  onRestart: () => void
  onUndo: () => void
}

export function Toolbar({ canUndo, onRestart, onUndo }: ToolbarProps) {
  return (
    <div
      className="grid w-full grid-cols-2 gap-3 sm:grid-cols-4"
      aria-label="Game tools"
    >
      <Button
        ariaLabel="Undo last move"
        disabled={!canUndo}
        icon={Undo2}
        onClick={onUndo}
        variant="primary"
      >
        Undo
      </Button>
      <Button ariaLabel="Hint placeholder" disabled icon={Lightbulb} variant="accent">
        Hint
      </Button>
      <Button ariaLabel="Restart puzzle" icon={RotateCcw} onClick={onRestart}>
        Restart
      </Button>
      <Button ariaLabel="Settings placeholder" disabled icon={Settings}>
        Settings
      </Button>
    </div>
  )
}
