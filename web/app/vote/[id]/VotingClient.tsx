// web/app/vote/[id]/VotingClient.tsx

'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import Image from 'next/image'
import { supabase } from '@/lib/supabase'
import { getVoterIdentifier } from '@/lib/fingerprint'
import { QUESTIONS, VotingSession, SCORE_DEFAULT } from '@/lib/types'
import VotingCard from '@/components/VotingCard'

type Props = {
  session: VotingSession
}

export default function VotingClient({ session }: Props) {
  const router = useRouter()
  const [submitting, setSubmitting] = useState(false)
  const [alreadyVoted, setAlreadyVoted] = useState(false)

  const [scores, setScores] = useState({
    score_courage: SCORE_DEFAULT,
    score_honesty: SCORE_DEFAULT,
    score_loyalty: SCORE_DEFAULT,
    score_work_ethic: SCORE_DEFAULT,
    score_discipline: SCORE_DEFAULT,
  })

  async function handleSubmit() {
    // Validate all scores are between 1-10
    const allScoresValid = Object.values(scores).every((score) => score >= 1 && score <= 10)
    if (!allScoresValid) {
      alert('Lütfen tüm soruları yanıtlayın.')
      return
    }

    try {
      setSubmitting(true)
      const { deviceId, ipAddress } = await getVoterIdentifier()

      console.log('🔍 Vote data:', {
        session_id: session.id,
        deviceId,
        ipAddress,
        scores,
      })

      const ipHash = await hashString(ipAddress || 'unknown')
      const fingerprintHash = await hashString(deviceId)

      console.log('🔐 Hashed:', { ipHash, fingerprintHash })

      // Check if already voted
      const { data: existingVote, error: checkError } = await supabase
        .from('votes')
        .select('id')
        .eq('voting_session_id', session.id)
        .eq('voter_fingerprint_hash', fingerprintHash)
        .maybeSingle()

      if (checkError) {
        console.error('❌ Check vote error:', checkError)
        console.error('Check error details:', JSON.stringify(checkError, null, 2))
      }

      if (existingVote) {
        console.warn('⚠️ User already voted')
        setAlreadyVoted(true)
        alert('Bu cihazdan zaten oy kullanılmış.')
        return
      }

      console.log('📤 Inserting vote...')

      // Insert vote
      const { data: voteData, error: voteError } = await supabase
        .from('votes')
        .insert({
          voting_session_id: session.id,
          voter_ip_hash: ipHash,
          voter_fingerprint_hash: fingerprintHash,
          score_courage: scores.score_courage,
          score_honesty: scores.score_honesty,
          score_loyalty: scores.score_loyalty,
          score_work_ethic: scores.score_work_ethic,
          score_discipline: scores.score_discipline,
        })
        .select()
        .single()

      if (voteError) {
        console.error('❌ Vote insert error:', voteError)
        console.error('Error code:', voteError.code)
        console.error('Error message:', voteError.message)
        console.error('Error details:', voteError.details)
        console.error('Error hint:', voteError.hint)
        throw new Error(`Vote insert failed: ${voteError.message}`)
      }

      console.log('✅ Vote inserted successfully:', voteData)

      // Success - redirect
      router.push('/vote/thank-you')
    } catch (err: any) {
      console.error('❌ Submit error:', err)
      const errorMessage = err.message || 'Bilinmeyen hata'
      alert(`Oy gönderilirken hata oluştu:\n${errorMessage}\n\nLütfen tekrar deneyin.`)
    } finally {
      setSubmitting(false)
    }
  }

  async function hashString(str: string): Promise<string> {
    const encoder = new TextEncoder()
    const data = encoder.encode(str)
    const hashBuffer = await crypto.subtle.digest('SHA-256', data)
    const hashArray = Array.from(new Uint8Array(hashBuffer))
    return hashArray.map((b) => b.toString(16).padStart(2, '0')).join('')
  }

  const allScoresValid = Object.values(scores).every((score) => score >= 1 && score <= 10)

  if (alreadyVoted) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-yellow-50 to-orange-50 flex items-center justify-center p-4">
        <div className="bg-white rounded-2xl shadow-xl p-8 max-w-md text-center">
          <div className="w-20 h-20 mx-auto mb-4 rounded-full bg-yellow-100 flex items-center justify-center">
            <svg
              className="w-10 h-10 text-yellow-500"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
              />
            </svg>
          </div>
          <h1 className="text-2xl font-bold mb-2 text-gray-800">Zaten Oy Kullandınız</h1>
          <p className="text-gray-600">Her cihazdan sadece bir kez oy kullanabilirsiniz.</p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-cyan-50 py-8 px-4">
      <div className="max-w-3xl mx-auto">
        {/* Header Card */}
        <div className="bg-white rounded-2xl shadow-xl p-8 mb-6 text-center">
          <div className="relative w-32 h-32 mx-auto mb-4 rounded-full overflow-hidden border-4 border-blue-500 shadow-lg">
            <Image
              src={session.photo_url}
              alt={session.full_name || 'Değerlendirilen Kişi'}
              fill
              className="object-cover"
            />
          </div>
          <h1 className="text-3xl font-bold mb-2 text-gray-800">Anonim Değerlendirme</h1>
          <p className="text-gray-600">5 soruyu cevaplayarak bu kişiyi değerlendirin</p>
          <div className="mt-4 inline-block bg-blue-100 px-4 py-2 rounded-full">
            <p className="text-sm text-blue-700 font-medium">✅ Oyunuz tamamen anonimdir</p>
          </div>
        </div>

        {/* Questions */}
        <div className="space-y-4 mb-6">
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
          className="w-full mt-6 bg-blue-600 text-white font-bold py-4 rounded-xl hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-all transform hover:scale-[1.02] active:scale-[0.98] shadow-lg"
        >
          {submitting ? (
            <span className="flex items-center justify-center">
              <svg
                className="animate-spin -ml-1 mr-3 h-5 w-5 text-white"
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
              >
                <circle
                  className="opacity-25"
                  cx="12"
                  cy="12"
                  r="10"
                  stroke="currentColor"
                  strokeWidth="4"
                ></circle>
                <path
                  className="opacity-75"
                  fill="currentColor"
                  d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                ></path>
              </svg>
              Gönderiliyor...
            </span>
          ) : (
            'Oyumu Gönder 🚀'
          )}
        </button>

        {/* Info Banner */}
        <div className="mt-6 bg-gray-50 border border-gray-200 rounded-xl p-4">
          <p className="text-sm text-gray-600 text-center">
            ℹ️ Oyunuz kaydedildikten sonra değiştirilemez. Lütfen dikkatli değerlendirin.
          </p>
        </div>
      </div>
    </div>
  )
}
