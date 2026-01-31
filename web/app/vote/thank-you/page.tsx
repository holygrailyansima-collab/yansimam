'use client'

import { useRouter } from 'next/navigation'
import { useEffect } from 'react'

export default function ThankYouPage() {
  const router = useRouter()

  useEffect(() => {
    const timer = setTimeout(() => {
      window.close()
    }, 5000)

    return () => clearTimeout(timer)
  }, [])

  return (
    <div className='min-h-screen bg-gradient-to-br from-green-50 to-emerald-50 flex items-center justify-center p-4'>
      <div className='bg-white rounded-2xl shadow-xl p-8 max-w-md w-full text-center'>
        <div className='w-20 h-20 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-6'>
          <svg className='w-10 h-10 text-green-600' fill='none' stroke='currentColor' viewBox='0 0 24 24'>
            <path strokeLinecap='round' strokeLinejoin='round' strokeWidth={2} d='M5 13l4 4L19 7' />
          </svg>
        </div>

        <h1 className='text-3xl font-bold text-gray-900 mb-4'>
          Teşekkürler!
        </h1>
        
        <p className='text-gray-600 mb-6'>
          Oyunuz başarıyla kaydedildi. Değerlendirmeniz tamamen anonim ve güvenlidir.
        </p>

        <div className='bg-blue-50 rounded-lg p-4 mb-6'>
          <p className='text-sm text-blue-800'>
            Bu sayfa 5 saniye içinde otomatik olarak kapanacak.
          </p>
        </div>

        <button
          onClick={() => window.close()}
          className='w-full bg-gray-100 hover:bg-gray-200 text-gray-700 font-semibold py-3 px-6 rounded-xl transition-colors'
        >
          Pencereyi Kapat
        </button>
      </div>
    </div>
  )
}
