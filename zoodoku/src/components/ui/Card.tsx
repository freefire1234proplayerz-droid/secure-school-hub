import type { ReactNode } from 'react'

type CardProps = {
  children: ReactNode
}

export function Card({ children }: CardProps) {
  return (
    <section className="w-full rounded-[2rem] border border-[#ECE7DD] bg-white p-4 shadow-[0_22px_60px_rgba(45,52,54,0.09)] sm:p-6 lg:p-8">
      {children}
    </section>
  )
}
