// web/app/page.tsx

import { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Yansımam - Dijital Kimliğini Sosyal Çevrenle Doğrula',
  description:
    'Sosyal çevrenizin görüşüyle dijital kimliğinizi doğrulayın. 72 saatlik onay süreci ile DeservePage ID kazanın.',
}

export default function HomePage() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-purple-50 to-pink-50">
      {/* Hero Section */}
      <div className="container mx-auto px-4 py-16">
        <div className="max-w-5xl mx-auto">
          {/* Logo & Tagline */}
          <div className="text-center mb-16">
            <h1 className="text-6xl md:text-7xl font-bold bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent mb-4">
              YANSIMAM
            </h1>
            <p className="text-2xl md:text-3xl text-gray-700 font-semibold mb-2">
              Cesaretin ve Özgüvenin Başladığı Yer 💙
            </p>
            <p className="text-lg text-gray-600">
              Dijital Kimliğini Sosyal Çevrenle Doğrula
            </p>
          </div>

          {/* Main Value Proposition */}
          <div className="bg-white rounded-3xl shadow-2xl p-8 md:p-12 mb-12">
            <h2 className="text-3xl md:text-4xl font-bold text-gray-800 mb-6 text-center">
              Güven, Algoritmalarla Değil <br />
              <span className="text-blue-600">Gerçek İnsanlar</span> Tarafından Oluşturulur
            </h2>
            <p className="text-lg text-gray-600 mb-8 text-center leading-relaxed max-w-3xl mx-auto">
              Sosyal çevreniz sizi <strong>5 farklı kişilik özelliğinde</strong> değerlendirir.{' '}
              <span className="font-bold text-blue-600">%50.01 veya üzeri onay</span> aldığınızda
              benzersiz bir{' '}
              <span className="font-bold text-purple-600">DeservePage ID</span> kazanırsınız.
            </p>

            {/* Download Buttons */}
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <a
                href="#"
                className="bg-black text-white px-8 py-4 rounded-xl font-bold text-lg hover:bg-gray-800 transition-all flex items-center justify-center gap-3"
              >
                <svg className="w-8 h-8" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
                </svg>
                App Store
              </a>
              <a
                href="#"
                className="bg-green-600 text-white px-8 py-4 rounded-xl font-bold text-lg hover:bg-green-700 transition-all flex items-center justify-center gap-3"
              >
                <svg className="w-8 h-8" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M3,20.5V3.5C3,2.91 3.34,2.39 3.84,2.15L13.69,12L3.84,21.85C3.34,21.6 3,21.09 3,20.5M16.81,15.12L6.05,21.34L14.54,12.85L16.81,15.12M20.16,10.81C20.5,11.08 20.75,11.5 20.75,12C20.75,12.5 20.53,12.9 20.18,13.18L17.89,14.5L15.39,12L17.89,9.5L20.16,10.81M6.05,2.66L16.81,8.88L14.54,11.15L6.05,2.66Z"/>
                </svg>
                Google Play
              </a>
            </div>
          </div>

          {/* Features */}
          <div className="grid md:grid-cols-3 gap-8 mb-12">
            <div className="bg-white rounded-2xl shadow-lg p-8 text-center">
              <div className="text-5xl mb-4">⏱️</div>
              <h3 className="text-xl font-bold text-gray-800 mb-3">72 Saat</h3>
              <p className="text-gray-600">
                Oylama süresi boyunca arkadaşlarınız sizi değerlendirir
              </p>
            </div>

            <div className="bg-white rounded-2xl shadow-lg p-8 text-center">
              <div className="text-5xl mb-4">🔒</div>
              <h3 className="text-xl font-bold text-gray-800 mb-3">%100 Anonim</h3>
              <p className="text-gray-600">
                Kimin oy verdiğini ve ne oy verdiğini asla göremezsiniz
              </p>
            </div>

            <div className="bg-white rounded-2xl shadow-lg p-8 text-center">
              <div className="text-5xl mb-4">🎯</div>
              <h3 className="text-xl font-bold text-gray-800 mb-3">5 Kategori</h3>
              <p className="text-gray-600">
                Cesaret, dürüstlük, bağlılık, çalışma azmi ve öz disiplin
              </p>
            </div>
          </div>

          {/* How It Works */}
          <div className="bg-white rounded-3xl shadow-2xl p-8 md:p-12 mb-12">
            <h2 className="text-3xl font-bold text-gray-800 mb-10 text-center">
              📋 Nasıl Çalışır?
            </h2>
            <div className="grid md:grid-cols-4 gap-8">
              <div className="text-center">
                <div className="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center text-blue-600 font-bold text-2xl mb-4 mx-auto">
                  1
                </div>
                <h3 className="font-bold text-gray-800 mb-2 text-lg">Uygulamayı İndir</h3>
                <p className="text-sm text-gray-600">
                  YANSIMAM mobil uygulamasını indirin ve kayıt olun
                </p>
              </div>

              <div className="text-center">
                <div className="w-16 h-16 bg-purple-100 rounded-full flex items-center justify-center text-purple-600 font-bold text-2xl mb-4 mx-auto">
                  2
                </div>
                <h3 className="font-bold text-gray-800 mb-2 text-lg">Link Paylaş</h3>
                <p className="text-sm text-gray-600">
                  Benzersiz oylamanızı oluşturun ve sosyal medyada paylaşın
                </p>
              </div>

              <div className="text-center">
                <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center text-green-600 font-bold text-2xl mb-4 mx-auto">
                  3
                </div>
                <h3 className="font-bold text-gray-800 mb-2 text-lg">Oylar Gelsin</h3>
                <p className="text-sm text-gray-600">
                  72 saat boyunca arkadaşlarınız sizi değerlendirsin
                </p>
              </div>

              <div className="text-center">
                <div className="w-16 h-16 bg-yellow-100 rounded-full flex items-center justify-center text-yellow-600 font-bold text-2xl mb-4 mx-auto">
                  4
                </div>
                <h3 className="font-bold text-gray-800 mb-2 text-lg">ID Kazan</h3>
                <p className="text-sm text-gray-600">
                  %50.01+ onay ile benzersiz DeservePage ID
                </p>
              </div>
            </div>
          </div>

          {/* FAQ */}
          <div className="bg-white rounded-3xl shadow-2xl p-8 md:p-12 mb-12">
            <h2 className="text-3xl font-bold text-gray-800 mb-8 text-center">
              ❓ Sıkça Sorulan Sorular
            </h2>
            <div className="space-y-6 max-w-3xl mx-auto">
              <div>
                <h3 className="font-bold text-gray-800 mb-2">Oylar gerçekten anonim mi?</h3>
                <p className="text-gray-600 text-sm">
                  Evet, %100 anonim. Kimin oy verdiğini ve ne oy verdiğini asla göremezsiniz.
                  Sadece toplam istatistikleri görürsünüz.
                </p>
              </div>
              <div>
                <h3 className="font-bold text-gray-800 mb-2">Başarısız olursam ne olur?</h3>
                <p className="text-gray-600 text-sm">
                  30 gün bekleyip tekrar deneyebilirsiniz. Daha fazla kişiyle paylaşmayı deneyin.
                </p>
              </div>
              <div>
                <h3 className="font-bold text-gray-800 mb-2">DeservePage ID nedir?</h3>
                <p className="text-gray-600 text-sm">
                  Gelecekte lansmanı yapılacak DeservePage sosyal medya platformunda
                  kullanacağınız benzersiz dijital kimliğinizdir.
                </p>
              </div>
            </div>
          </div>

          {/* Contact & Legal */}
          <div className="bg-white rounded-3xl shadow-2xl p-8 md:p-12 text-center">
            <h2 className="text-2xl font-bold text-gray-800 mb-6">📞 İletişim & Yasal</h2>
            <div className="space-y-3 text-sm text-gray-600 mb-6">
              <p>
                <strong>E-posta Desteği:</strong>{' '}
                <a href="mailto:destek@yansimam.com" className="text-blue-600 hover:underline">
                  destek@yansimam.com
                </a>
              </p>
              <p>
                <strong>Web:</strong>{' '}
                <a href="https://yansimam.com" className="text-blue-600 hover:underline">
                  yansimam.com
                </a>
              </p>
              <p className="font-mono text-xs text-gray-500">
                MERSIS NO: 0937162221400001
              </p>
            </div>
            <div className="flex flex-wrap justify-center gap-4 text-xs">
              <a href="#" className="text-gray-600 hover:text-blue-600">
                Kullanım Şartları
              </a>
              <a href="#" className="text-gray-600 hover:text-blue-600">
                Gizlilik Politikası
              </a>
              <a href="#" className="text-gray-600 hover:text-blue-600">
                GDPR/KVKK Uyumluluğu
              </a>
              <a href="#" className="text-gray-600 hover:text-blue-600">
                Çerez Politikası
              </a>
            </div>
            <p className="text-xs text-gray-500 mt-6">
              🔒 GDPR, KVKK ve CCPA uyumlu • Verileriniz güvende ve şifrelenmiştir
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}
