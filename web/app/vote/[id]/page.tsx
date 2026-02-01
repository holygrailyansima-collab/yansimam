// web/app/vote/[id]/page.tsx

import { Metadata } from 'next'
import { notFound } from 'next/navigation'
import VotingClient from './VotingClient'
import { supabase } from '@/lib/supabase'

type Props = {
  params: Promise<{ id: string }>
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { id } = await params
  return {
    title: `Yansımam - ${id} İçin Oy Ver`,
    description: 'Sosyal çevrenizin görüşüyle dijital kimliğinizi doğrulayın',
  }
}

async function loadSession(uniqueLink: string) {
  try {
    console.log('🔍 Loading session:', uniqueLink)

    const { data: sessionData, error: sessionError } = await supabase
      .from('voting_sessions')
      .select(
        `
        id,
        user_id,
        unique_link,
        expires_at,
        photo_url,
        status,
        user:users!inner (
          id,
          full_name,
          profile_photo_url
        )
      `
      )
      .eq('unique_link', uniqueLink)
      .eq('status', 'active')
      .single()

    if (sessionError) {
      console.error('❌ Session query error:', sessionError)
      return { error: 'Oylama bulunamadı (Veritabanı hatası)' }
    }

    if (!sessionData) {
      console.error('❌ No session found')
      return { error: 'Oylama bulunamadı veya süresi dolmuş' }
    }

    // Type cast: user is a single object, not array
    const userData = Array.isArray(sessionData.user) ? sessionData.user[0] : sessionData.user

    console.log('✅ Session found:', {
      id: sessionData.id,
      photo_url: sessionData.photo_url,
      user_photo: userData?.profile_photo_url,
    })

    const expiryDate = new Date(sessionData.expires_at)
    if (expiryDate < new Date()) {
      return { error: 'Oylamanın süresi dolmuş' }
    }

    const photoUrl = sessionData.photo_url || userData?.profile_photo_url

    if (!photoUrl) {
      console.error('❌ No photo found:', {
        session_photo: sessionData.photo_url,
        user_photo: userData?.profile_photo_url,
      })
      return { error: 'Fotoğraf bulunamadı. Lütfen oylama oluşturanla iletişime geçin.' }
    }

    return {
      session: {
        id: sessionData.id,
        user_id: sessionData.user_id,
        unique_link: sessionData.unique_link,
        expires_at: sessionData.expires_at,
        photo_url: photoUrl,
        full_name: userData?.full_name || 'Kullanıcı',
      },
    }
  } catch (err) {
    console.error('❌ Unexpected error:', err)
    return { error: 'Beklenmeyen bir hata oluştu' }
  }
}

export default async function VotePage({ params }: Props) {
  const { id } = await params
  const result = await loadSession(id)

  if ('error' in result) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-red-50 to-pink-50 p-4">
        <div className="bg-white rounded-2xl shadow-xl p-8 max-w-md text-center">
          <div className="w-20 h-20 mx-auto mb-4 rounded-full bg-red-100 flex items-center justify-center">
            <svg
              className="w-10 h-10 text-red-500"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M6 18L18 6M6 6l12 12"
              />
            </svg>
          </div>
          <h1 className="text-2xl font-bold mb-2 text-gray-800">❌ Hata</h1>
          <p className="text-gray-600 mb-6">{result.error}</p>
          <a
            href="https://yansimam.vercel.app"
            className="inline-block bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 transition-colors"
          >
            Ana Sayfaya Dön
          </a>
        </div>
      </div>
    )
  }

  return <VotingClient session={result.session} />
}
