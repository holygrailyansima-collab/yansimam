'use client'

import { useEffect, useState } from 'react'
import { useParams, useRouter } from 'next/navigation'
import Image from 'next/image'
import { supabase } from '@/lib/supabase'
import { getVoterIdentifier } from '@/lib/fingerprint'
import { QUESTIONS, VotingSession } from '@/lib/types'
import VotingCard from '@/components/VotingCard'

export default function VotePage() {
  const params = useParams()
  const router = useRouter()
  const linkId = params.id as string

  const [loading, setLoading] = useState(true)
  const [submitting, setSubmitting] = useState(false)
  const [session, setSession] = useState<VotingSession | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [alreadyVoted, setAlreadyVoted] = useState(false)

  const [scores, setScores] = useState({
    score_courage: 5,
    score_honesty: 5,
    score_loyalty: 5,
    score_work_ethic: 5,
    score_discipline: 5,
  })

  useEffect(() => {
    loadSession()
  }, [linkId])

  async function loadSession() {
    try {
      setLoading(true)
      setError(null)

      // Fetch session by unique_link (not voting_link!)
      const { data: sessionData, error: sessionError } = await supabase
        .from('voting_sessions')
        .select('*')
        .eq('unique_link', linkId) // ✅ Fixed: unique_link
        .single()

      if (sessionError || !sessionData) {
        setError('Oylama bulunamadı.')
        console.error('Session error:', sessionError)
        return
      }

      // Check if session expired
      const expiryDate = new Date(sessionData.expires_at)
      if (expiryDate < new Date()) {
        setError('Oylamanın süresi dolmuş.')
        return
      }

      // Check if already voted (by device fingerprint)
      const { deviceId } = await getVoterIdentifier()
      const { data: existingVote } = await supabase
        .from('votes')
        .select('id')
        .eq('voting_session_id', sessionData.id) // ✅ Fixed: voting_session_id
        .eq('voter_fingerprint_hash', deviceId) // ✅ Fixed: voter_fingerprint_hash
        .single()

      if (existingVote) {
        setAlreadyVoted(true)
        setError('Bu cihazdan zaten oy kullanılmış.')
        return
      }

      setSession(sessionData)
    } catch (err) {
      console.error('Error loading session:', err)
      setError('Bir hata oluştu.')
    } finally {
      setLoading(false)
    }
  }

  async function handleSubmit() {
    if (!session) return

    // Validate all scores filled
    const allScoresFilled = Object.values(scores).every((score) => score >= 0 && score <= 10)
    if (!allScoresFilled) {
      alert('Lütfen tüm soruları yanıtlayın.')
      return
    }

    try {
      setSubmitting(true)
      const { deviceId, ipAddress } = await getVoterIdentifier()

      // Calculate average score
      const averageScore =
        (scores.score_courage +
          scores.score_honesty +
          scores.score_loyalty +
          scores.score_work_ethic +
          scores.score_discipline) /
        5

      // Hash IP and fingerprint for privacy
      const ipHash = await hashString(ipAddress || 'unknown')
      const fingerprintHash = await hashString(deviceId)

      // Insert vote
      const { error: voteError } = await supabase.from('votes').insert({
        voting_session_id: session.id, // ✅ Fixed: voting_session_id
        voter_ip_hash: ipHash, // ✅ Fixed: voter_ip_hash
        voter_fingerprint_hash: fingerprintHash, // ✅ Fixed: voter_fingerprint_hash
        score_courage: scores.score_courage,
        score_honesty: scores.score_honesty,
        score_loyalty: scores.score_loyalty,
        score_work_ethic: scores.score_work_ethic,
        score_discipline: scores.score_discipline,
        // average_score is GENERATED in SQL (no need to insert)
      })

      if (voteError) {
        console.error('Vote insert error:', voteError)
        throw voteError
      }

      // Navigate to thank you page
      router.push('/vote/thank-you')
    } catch (err) {
      console.error('Submit error:', err)
      alert('Oy gönderilirken hata oluştu. Lütfen tekrar deneyin.')
    } finally {
      setSubmitting(false)
    }
  }

  // Simple hash function for privacy
  async function hashString(str: string): Promise<string> {
    const encoder = new TextEncoder()
    const data = encoder.encode(str)
    const hashBuffer = await crypto.subtle.digest('SHA-256', data)
    const hashArray = Array.from(new Uint8Array(hashBuffer))
    return hashArray.map((b) => b.toString(16).padStart(2, '0')).join('')
  }

  if (loading) {
    return (
      <div className='min-h-screen bg-gradient-to-br from-blue-50 to-cyan-50 flex items-center justify-center'>
        <div className='animate-spin rounded-full h-16 w-16 border-b-2 border-blue-600'></div>
      </div>
    )
  }

  if (error) {
    return (
      <div className='min-h-screen bg-gradient-to-br from-blue-50 to-cyan-50 flex items-center justify-center p-4'>
        <div className='bg-white rounded-2xl shadow-xl p-8 max-w-md text-center'>
          <div className='w-20 h-20 mx-auto mb-4 rounded-full bg-red-100 flex items-center justify-center'>
            <svg
              className='w-10 h-10 text-red-500'
              fill='none'
              stroke='currentColor'
              viewBox='0 0 24 24'
            >
              <path
                strokeLinecap='round'
                strokeLinejoin='round'
                strokeWidth={2}
                d='M6 18L18 6M6 6l12 12'
              />
            </svg>
          </div>
          <h1 className='text-2xl font-bold mb-2 text-gray-800'>
            {alreadyVoted ? 'Zaten Oy Kullandınız' : 'Hata'}
          </h1>
          <p className='text-gray-600'>{error}</p>
          {alreadyVoted && (
            <p className='text-sm text-gray-500 mt-4'>
              Her cihazdan sadece bir kez oy kullanabilirsiniz.
            </p>
          )}
        </div>
      </div>
    )
  }

  if (!session) return null

  const allScoresValid = Object.values(scores).every((score) => score >= 0 && score <= 10)

  return (
    <div className='min-h-screen bg-gradient-to-br from-blue-50 to-cyan-50 py-8 px-4'>
      <div className='max-w-3xl mx-auto'>
        {/* Header Card */}
        <div className='bg-white rounded-2xl shadow-xl p-8 mb-6 text-center'>
          <div className='relative w-32 h-32 mx-auto mb-4 rounded-full overflow-hidden border-4 border-blue-500 shadow-lg'>
            <Image
              src={session.photo_url}
              alt='Değerlendirilen Kişi'
              fill
              className='object-cover'
            />
          </div>
          <h1 className='text-3xl font-bold mb-2 text-gray-800'>Anonim Değerlendirme</h1>
          <p className='text-gray-600'>
            5 soruyu cevaplayarak bu kişiyi değerlendirin
          </p>
          <div className='mt-4 inline-block bg-blue-100 px-4 py-2 rounded-full'>
            <p className='text-sm text-blue-700 font-medium'>
              ✅ Oyunuz tamamen anonimdir
            </p>
          </div>
        </div>

        {/* Questions */}
        <div className='space-y-4 mb-6'>
          {QUESTIONS.map((q) => (
            <VotingCard
              key={q.id}
              question={q}
              value={scores[q.key]}
              onChange={(v) => setScores({ ...scores, [q.key]: v })}
            />
          ))}
        </div>

        {/* Submit Button */}
        <button
          onClick={handleSubmit}
          disabled={!allScoresValid || submitting}
          className='w-full mt-6 bg-blue-600 text-white font-bold py-4 rounded-xl hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-all transform hover:scale-[1.02] active:scale-[0.98] shadow-lg'
        >
          {submitting ? (
            <span className='flex items-center justify-center'>
              <svg
                className='animate-spin -ml-1 mr-3 h-5 w-5 text-white'
                xmlns='http://www.w3.org/2000/svg'
                fill='none'
                viewBox='0 0 24 24'
              >
                <circle
                  className='opacity-25'
                  cx='12'
                  cy='12'
                  r='10'
                  stroke='currentColor'
                  strokeWidth='4'
                ></circle>
                <path
                  className='opacity-75'
                  fill='currentColor'
                  d='M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z'
                ></path>
              </svg>
              Gönderiliyor...
            </span>
          ) : (
            'Oyumu Gönder 🚀'
          )}
        </button>

        {/* Info Banner */}
        <div className='mt-6 bg-gray-50 border border-gray-200 rounded-xl p-4'>
          <p className='text-sm text-gray-600 text-center'>
            ℹ️ Oyunuz kaydedildikten sonra değiştirilemez. Lütfen dikkatli değerlendirin.
          </p>
        </div>
      </div>
    </div>
  )
}
