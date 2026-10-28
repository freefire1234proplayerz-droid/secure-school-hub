import { BarChart3, Palette, Settings } from 'lucide-react'
import { Button } from './ui/Button'

export function Header() {
  return (
    <header className="flex w-full flex-col gap-5 sm:flex-row sm:items-center sm:justify-between">
      <div className="text-center sm:text-left">
        <div className="inline-flex items-center gap-2 rounded-full border border-[#ECE7DD] bg-white px-3 py-1.5 shadow-[0_8px_20px_rgba(45,52,54,0.05)]">
          <span className="h-2.5 w-2.5 rounded-full bg-[#6FCF97]" />
          <span className="text-xs font-extrabold uppercase tracking-[0.16em] text-[#7B7B7B]">
            Zoodoku
          </span>
        </div>
        <h1 className="mt-3 font-['Fredoka'] text-5xl font-bold leading-none text-[#2D3436] sm:text-6xl">
          Zoodoku
        </h1>
        <p className="mt-2 text-base font-semibold text-[#7B7B7B] sm:text-lg">
          Every animal deserves a home.
        </p>
      </div>

      <nav
        className="flex items-center justify-center gap-2"
        aria-label="Future game menus"
      >
        <Button ariaLabel="Settings placeholder" disabled icon={Settings}>
          Settings
        </Button>
        <Button ariaLabel="Statistics placeholder" disabled icon={BarChart3}>
          Statistics
        </Button>
        <Button ariaLabel="Theme placeholder" disabled icon={Palette}>
          Theme
        </Button>
      </nav>
    </header>
  )
}
