import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'YANSIMAM - Anonim Değerlendirme',
  description: 'Sosyal çevrenizin görüşü önemli',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang='tr'>
      <body className='antialiased'>{children}</body>
    </html>
  )
}
