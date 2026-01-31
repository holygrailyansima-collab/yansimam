import FingerprintJS from '@fingerprintjs/fingerprintjs'

let fpPromise: Promise<any> | null = null

export async function getDeviceFingerprint(): Promise<string> {
  try {
    if (!fpPromise) {
      fpPromise = FingerprintJS.load()
    }
    const fp = await fpPromise
    const result = await fp.get()
    return result.visitorId
  } catch (error) {
    console.error('Fingerprint error:', error)
    return 'fallback-' + Date.now() + '-' + Math.random().toString(36).substr(2, 9)
  }
}

export async function getVoterIdentifier() {
  const deviceId = await getDeviceFingerprint()
  return { deviceId, ipAddress: 'server-side' }
}
