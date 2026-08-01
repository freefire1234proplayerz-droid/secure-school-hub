import type { ComponentType, ReactNode } from 'react'
import type { LucideProps } from 'lucide-react'

type ButtonProps = {
  ariaLabel: string
  children: ReactNode
  disabled?: boolean
  icon?: ComponentType<LucideProps>
  onClick?: () => void
  variant?: 'primary' | 'accent' | 'neutral'
}

const variantStyles = {
  primary: 'border-[#BCEBCF] bg-[#EAF9F0] text-[#25784B]',
  accent: 'border-[#F8E7A7] bg-[#FFF6D7] text-[#8A6A00]',
  neutral: 'border-[#ECE7DD] bg-white text-[#2D3436]',
}

export function Button({
  ariaLabel,
  children,
  disabled = false,
  icon: Icon,
  onClick,
  variant = 'neutral',
}: ButtonProps) {
  return (
    <button
      type="button"
      aria-label={ariaLabel}
      disabled={disabled}
      onClick={onClick}
      className={`inline-flex min-h-11 items-center justify-center gap-2 rounded-full border px-4 py-2 text-sm font-extrabold shadow-[0_8px_18px_rgba(45,52,54,0.05)] transition hover:-translate-y-0.5 hover:shadow-[0_12px_24px_rgba(45,52,54,0.08)] focus-visible:outline-3 focus-visible:outline-offset-3 focus-visible:outline-[#6FCF97] disabled:cursor-not-allowed disabled:opacity-70 ${variantStyles[variant]}`}
    >
      {Icon ? <Icon aria-hidden="true" size={18} strokeWidth={2.4} /> : null}
      <span>{children}</span>
    </button>
  )
}
