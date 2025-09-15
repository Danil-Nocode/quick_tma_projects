import crypto from 'crypto'

export interface TelegramUser {
  id: number
  first_name?: string
  last_name?: string
  username?: string
  language_code?: string
  allows_write_to_pm?: boolean
  photo_url?: string
}

export interface TelegramWebAppData {
  user: TelegramUser
  chat_instance?: string
  chat_type?: string
  auth_date: number
  hash: string
}

/**
 * Validates Telegram Web App initData using HMAC-SHA256
 * @param initData - The initData string from Telegram.WebApp.initData
 * @param botToken - Telegram bot token
 * @returns Parsed user data if valid, null if invalid
 */
export function validateTelegramWebAppData(
  initData: string,
  botToken: string
): TelegramWebAppData | null {
  try {
    const urlParams = new URLSearchParams(initData)
    const hash = urlParams.get('hash')
    
    if (!hash) {
      return null
    }

    // Remove hash from params for validation
    urlParams.delete('hash')
    
    // Sort params and create data string
    const dataCheckString = Array.from(urlParams.entries())
      .sort(([a], [b]) => a.localeCompare(b))
      .map(([key, value]) => `${key}=${value}`)
      .join('\n')

    // Create secret key from bot token
    const secretKey = crypto
      .createHmac('sha256', 'WebAppData')
      .update(botToken)
      .digest()

    // Calculate expected hash
    const expectedHash = crypto
      .createHmac('sha256', secretKey)
      .update(dataCheckString)
      .digest('hex')

    // Verify hash
    if (hash !== expectedHash) {
      return null
    }

    // Parse user data
    const userData = urlParams.get('user')
    if (!userData) {
      return null
    }

    const user = JSON.parse(userData) as TelegramUser
    const authDate = parseInt(urlParams.get('auth_date') || '0')
    
    // Check if data is not too old (24 hours)
    const now = Math.floor(Date.now() / 1000)
    if (now - authDate > 86400) {
      return null
    }

    return {
      user,
      chat_instance: urlParams.get('chat_instance') || undefined,
      chat_type: urlParams.get('chat_type') || undefined,
      auth_date: authDate,
      hash
    }
  } catch (error) {
    console.error('Telegram data validation error:', error)
    return null
  }
}
