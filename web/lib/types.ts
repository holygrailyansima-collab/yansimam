// web/lib/types.ts

export interface User {
  id: string
  email: string
  full_name: string
  username?: string
  profile_photo_url?: string
  created_at: string
  updated_at?: string
}

export interface VotingSession {
  id: string
  user_id: string
  unique_link: string
  photo_url: string
  full_name: string
  qr_code_url?: string
  start_time?: string
  end_time?: string
  expires_at: string
  status?: 'active' | 'completed' | 'expired'
  total_votes?: number
  approval_rate?: number
  average_score?: number
  score_courage?: number
  score_honesty?: number
  score_loyalty?: number
  score_work_ethic?: number
  score_discipline?: number
  created_at?: string
  updated_at?: string
}

export interface Vote {
  id: string
  voting_session_id: string
  voter_ip_hash: string
  voter_fingerprint_hash: string
  score_courage: number
  score_honesty: number
  score_loyalty: number
  score_work_ethic: number
  score_discipline: number
  average_score: number
  created_at: string
}

export interface Question {
  id: number
  key: 'score_courage' | 'score_honesty' | 'score_loyalty' | 'score_work_ethic' | 'score_discipline'
  text: string
  description: string
  minLabel: string
  maxLabel: string
}

export const QUESTIONS: Question[] = [
  {
    id: 1,
    key: 'score_courage',
    text: 'Cesaret ve Risk Alma',
    description: 'Bu kişinin zorluklar karşısında gösterdiği cesaret ve risk alma yeteneğini 1-10 arası değerlendirin',
    minLabel: 'Çok Düşük',
    maxLabel: 'Çok Yüksek',
  },
  {
    id: 2,
    key: 'score_honesty',
    text: 'Dürüstlük ve Güvenilirlik',
    description: 'Bu kişinin dürüstlük, güvenilirlik ve şeffaflık derecesini 1-10 arası değerlendirin',
    minLabel: 'Çok Düşük',
    maxLabel: 'Çok Yüksek',
  },
  {
    id: 3,
    key: 'score_loyalty',
    text: 'Bağlılık ve Sadakat',
    description: 'Bu kişinin bağlılık, sadakat ve güvenilirlik seviyesini 1-10 arası değerlendirin',
    minLabel: 'Çok Düşük',
    maxLabel: 'Çok Yüksek',
  },
  {
    id: 4,
    key: 'score_work_ethic',
    text: 'Çalışma Azmi',
    description: 'Bu kişinin çalışma azmi, üretkenlik ve gayret derecesini 1-10 arası değerlendirin',
    minLabel: 'Çok Düşük',
    maxLabel: 'Çok Yüksek',
  },
  {
    id: 5,
    key: 'score_discipline',
    text: 'Öz Disiplin',
    description: 'Bu kişinin öz disiplin, düzen ve sistemlilik seviyesini 1-10 arası değerlendirin',
    minLabel: 'Çok Düşük',
    maxLabel: 'Çok Yüksek',
  },
]

// Score constants
export const SCORE_MIN = 1
export const SCORE_MAX = 10
export const SCORE_STEP = 0.5
export const SCORE_DEFAULT = 5.5
