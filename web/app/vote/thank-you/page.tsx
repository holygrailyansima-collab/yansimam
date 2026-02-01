// web/app/vote/thank-you/page.tsx

import { Metadata } from 'next'
import Link from 'next/link'

export const metadata: Metadata = {
  title: 'Teşekkürler - Yansımam',
  description: 'Oyunuz başarıyla kaydedildi',
}

export default function ThankYouPage() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-green-50 to-emerald-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-xl p-8 max-w-md text-center">
        {/* Success Icon */}
        <div className="w-20 h-20 mx-auto mb-6 rounded-full bg-green-100 flex items-center justify-center animate-bounce">
          <svg
            className="w-10 h-10 text-green-500"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M5 13l4 4L19 7"
            />
          </svg>
        </div>

        {/* Title */}
        <h1 className="text-3xl font-bold text-gray-800 mb-4">Oyunuz Kaydedildi! 🎉</h1>

        {/* Message */}
        <p className="text-gray-600 mb-6">
          Katılımınız için teşekkür ederiz. Oyunuz tamamen anonimdir ve değerlendirmeye dahil
          edilmiştir.
        </p>

        {/* Divider */}
        <div className="border-t border-gray-200 my-6"></div>

        {/* Call to Action */}
        <div className="bg-blue-50 rounded-xl p-6 mb-6">
          <h2 className="text-xl font-bold text-gray-800 mb-2">📱 Sıra Sende!</h2>
          <p className="text-sm text-gray-600 mb-4">
            Gerçekliğini çevrenle doğrula. Dijital kimliğini sosyal onayınla güçlendir.
          </p>
          <Link
            href="https://yansimam.vercel.app"
            className="inline-block bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 transition-colors font-semibold"
          >
            YANSIMAM'a Katıl
          </Link>
        </div>

        {/* Footer Info */}
        <div className="text-xs text-gray-500">
          <p className="mb-2">💙 Verileriniz güvende ve şifrelenmiştir</p>
          <p>
            MERSIS NO:{' '}
            <span className="font-mono text-gray-700">0937162221400001</span>
          </p>
        </div>
      </div>
    </div>
  )
}
