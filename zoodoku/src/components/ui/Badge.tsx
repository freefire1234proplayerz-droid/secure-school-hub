import type { ReactNode } from 'react'

type BadgeProps = {
  children: ReactNode
  tone?: 'primary' | 'accent' | 'neutral'
}

const toneStyles = {
  primary: 'border-[#BCEBCF] bg-[#EAF9F0] text-[#25784B]',
  accent: 'border-[#F8E7A7] bg-[#FFF6D7] text-[#8A6A00]',
  neutral: 'border-[#ECE7DD] bg-[#FFFDF8] text-[#2D3436]',
}

export function Badge({ children, tone = 'neutral' }: BadgeProps) {
  return (
    <span
      className={`inline-flex items-center justify-center rounded-full border px-4 py-2 text-sm font-extrabold shadow-[0_8px_18px_rgba(45,52,54,0.05)] ${toneStyles[tone]}`}
    >
      {children}
    </span>
  )
}
