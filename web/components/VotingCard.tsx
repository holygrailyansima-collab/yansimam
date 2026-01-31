'use client'

import { useState } from 'react'

interface VotingCardProps {
  question: {
    id: number
    title: string
    description: string
    category: string
  }
  value: number
  onChange: (value: number) => void
}

export default function VotingCard({ question, value, onChange }: VotingCardProps) {
  const [localValue, setLocalValue] = useState(value)

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newValue = parseInt(e.target.value)
    setLocalValue(newValue)
    onChange(newValue)
  }

  const getColorClass = (score: number) => {
    if (score <= 3) return 'bg-red-500'
    if (score <= 6) return 'bg-yellow-500'
    return 'bg-green-500'
  }

  return (
    <div className='bg-white rounded-2xl shadow-lg p-6 border border-gray-100'>
      <div className='flex items-start gap-4 mb-4'>
        <div className='flex-shrink-0 w-12 h-12 rounded-full bg-gradient-to-br from-blue-500 to-cyan-500 flex items-center justify-center text-white font-bold text-lg'>
          {question.id}
        </div>
        <div className='flex-1'>
          <h3 className='text-xl font-bold text-gray-900 mb-1'>
            {question.title}
          </h3>
          <p className='text-sm text-gray-600'>
            {question.description}
          </p>
        </div>
      </div>

      <div className='space-y-4'>
        <div className='flex items-center justify-between'>
          <span className='text-sm font-medium text-gray-500'>Puan</span>
          <div className={`px-4 py-2 rounded-lg ${getColorClass(localValue)} text-white font-bold text-xl`}>
            {localValue}/10
          </div>
        </div>

        <div className='relative pt-2'>
          <input
            type='range'
            min='0'
            max='10'
            value={localValue}
            onChange={handleChange}
            className='w-full h-3 bg-gray-200 rounded-lg appearance-none cursor-pointer accent-blue-600'
            style={{
              background: `linear-gradient(to right, ${
                localValue <= 3 ? '#ef4444' : localValue <= 6 ? '#eab308' : '#22c55e'
              } 0%, ${
                localValue <= 3 ? '#ef4444' : localValue <= 6 ? '#eab308' : '#22c55e'
              } ${(localValue / 10) * 100}%, #e5e7eb ${(localValue / 10) * 100}%, #e5e7eb 100%)`
            }}
          />
          <div className='flex justify-between text-xs text-gray-500 mt-2'>
            <span>0</span>
            <span>5</span>
            <span>10</span>
          </div>
        </div>

        <div className='flex justify-between text-xs'>
          <span className='text-red-600 font-medium'>Düşük</span>
          <span className='text-yellow-600 font-medium'>Orta</span>
          <span className='text-green-600 font-medium'>Yüksek</span>
        </div>
      </div>
    </div>
  )
}
