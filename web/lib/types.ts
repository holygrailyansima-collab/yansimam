export interface VotingSession {
  id: string
  user_id: string
  photo_url: string
  voting_link: string
  expires_at: string
  total_votes: number
  status: 'active' | 'completed' | 'expired'
  created_at: string
}

export interface Vote {
  id: string
  session_id: string
  device_id: string
  ip_address: string | null
  trust_score: number
  responsibility_score: number
  communication_score: number
  empathy_score: number
  overall_score: number
  verdict: 'approve' | 'reject'
  created_at: string
}

export interface Question {
  id: number
  title: string
  description: string
  category: string
  key: 'trust_score' | 'responsibility_score' | 'communication_score' | 'empathy_score' | 'overall_score'
}

export const QUESTIONS: Question[] = [
  { id: 1, title: 'Güvenilirlik', description: 'Bu kişiye ne kadar güvenirsiniz?', category: 'Trust', key: 'trust_score' },
  { id: 2, title: 'Sorumluluk', description: 'Sorumluluklarını ne kadar yerine getirir?', category: 'Responsibility', key: 'responsibility_score' },
  { id: 3, title: 'İletişim', description: 'İletişim becerileri ne kadar gelişmiş?', category: 'Communication', key: 'communication_score' },
  { id: 4, title: 'Empati', description: 'Başkalarının duygularını ne kadar anlar?', category: 'Empathy', key: 'empathy_score' },
  { id: 5, title: 'Genel Değerlendirme', description: 'Genel olarak bu kişiyi nasıl değerlendirirsiniz?', category: 'Overall', key: 'overall_score' },
]
