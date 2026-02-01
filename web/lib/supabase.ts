// web/lib/supabase.ts

import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables!')
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: false,
    autoRefreshToken: false,
  },
  db: {
    schema: 'public',
  },
})

// Helper: Upload photo to Supabase Storage
export async function uploadVotingPhoto(file: File, userId: string): Promise<string> {
  try {
    // Generate unique filename
    const fileExt = file.name.split('.').pop()
    const fileName = `${userId}-${Date.now()}.${fileExt}`
    const filePath = `voting-photos/${fileName}`

    // Upload to Supabase Storage
    const { data, error } = await supabase.storage
      .from('voting-photos')
      .upload(filePath, file, {
        cacheControl: '3600',
        upsert: false,
      })

    if (error) {
      console.error('Upload error:', error)
      throw new Error('Fotoğraf yüklenemedi')
    }

    // Get public URL
    const { data: urlData } = supabase.storage
      .from('voting-photos')
      .getPublicUrl(filePath)

    return urlData.publicUrl
  } catch (err) {
    console.error('Upload error:', err)
    throw err
  }
}

// Helper: Generate unique link
export function generateUniqueLink(): string {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789'
  let result = ''
  for (let i = 0; i < 8; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length))
  }
  return result
}

// Helper: Calculate expiry date (72 hours)
export function getExpiryDate(): Date {
  const now = new Date()
  now.setHours(now.getHours() + 72)
  return now
}
