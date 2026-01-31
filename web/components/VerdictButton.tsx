'use client'

interface VerdictButtonProps {
  selected: 'approve' | 'reject' | null
  onSelect: (verdict: 'approve' | 'reject') => void
  disabled?: boolean
}

export default function VerdictButton({ selected, onSelect, disabled }: VerdictButtonProps) {
  return (
    <div className='bg-white rounded-2xl shadow-lg p-6 border border-gray-100'>
      <h3 className='text-xl font-bold text-gray-900 mb-2'>
        Son Kararınız
      </h3>
      <p className='text-sm text-gray-600 mb-6'>
        Genel değerlendirmenize göre kişiyi onaylıyor musunuz?
      </p>

      <div className='grid grid-cols-2 gap-4'>
        <button
          onClick={() => onSelect('approve')}
          disabled={disabled}
          className={`relative overflow-hidden px-6 py-4 rounded-xl font-bold text-lg transition-all duration-200 ${
            selected === 'approve'
              ? 'bg-green-500 text-white shadow-lg scale-105'
              : 'bg-gray-100 text-gray-700 hover:bg-green-50 hover:text-green-600'
          } disabled:opacity-50 disabled:cursor-not-allowed`}
        >
          <span className='relative z-10 flex items-center justify-center gap-2'>
            <svg className='w-6 h-6' fill='none' stroke='currentColor' viewBox='0 0 24 24'>
              <path strokeLinecap='round' strokeLinejoin='round' strokeWidth={2} d='M5 13l4 4L19 7' />
            </svg>
            Onaylıyorum
          </span>
        </button>

        <button
          onClick={() => onSelect('reject')}
          disabled={disabled}
          className={`relative overflow-hidden px-6 py-4 rounded-xl font-bold text-lg transition-all duration-200 ${
            selected === 'reject'
              ? 'bg-red-500 text-white shadow-lg scale-105'
              : 'bg-gray-100 text-gray-700 hover:bg-red-50 hover:text-red-600'
          } disabled:opacity-50 disabled:cursor-not-allowed`}
        >
          <span className='relative z-10 flex items-center justify-center gap-2'>
            <svg className='w-6 h-6' fill='none' stroke='currentColor' viewBox='0 0 24 24'>
              <path strokeLinecap='round' strokeLinejoin='round' strokeWidth={2} d='M6 18L18 6M6 6l12 12' />
            </svg>
            Onaylamıyorum
          </span>
        </button>
      </div>
    </div>
  )
}
