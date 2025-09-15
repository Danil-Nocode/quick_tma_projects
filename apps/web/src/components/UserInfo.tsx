import { TelegramUser, TelegramWebApp } from '../hooks/useTelegram'

interface UserInfoProps {
  user: TelegramUser | null
  webApp: TelegramWebApp | null
  initDataAvailable: boolean
}

export const UserInfo = ({ user, webApp, initDataAvailable }: UserInfoProps) => {
  if (!user) {
    return (
      <div className="user-card">
        <div className="user-info">
          <h3>👤 Пользователь не определён</h3>
          <p>Откройте приложение через Telegram бота для авторизации</p>
          {!initDataAvailable && (
            <p style={{ color: '#ff4757', marginTop: '8px' }}>
              ⚠️ initData недоступен
            </p>
          )}
        </div>
      </div>
    )
  }

  const fullName = [user.first_name, user.last_name].filter(Boolean).join(' ')

  return (
    <div className="user-card">
      <div className="user-info">
        <h3>👤 {fullName || 'Telegram User'}</h3>
        <p><strong>ID:</strong> {user.id}</p>
        {user.username && <p><strong>Username:</strong> @{user.username}</p>}
        {user.language_code && <p><strong>Язык:</strong> {user.language_code}</p>}
        
        <div style={{ marginTop: '12px', fontSize: '12px', opacity: 0.7 }}>
          <p><strong>Telegram WebApp:</strong> {webApp?.version || 'N/A'}</p>
          <p><strong>Платформа:</strong> {webApp?.platform || 'Browser'}</p>
          <p><strong>Схема:</strong> {webApp?.colorScheme || 'light'}</p>
          {initDataAvailable ? (
            <p style={{ color: '#2ed573' }}>✅ InitData получен</p>
          ) : (
            <p style={{ color: '#ff4757' }}>❌ InitData отсутствует</p>
          )}
        </div>
      </div>
    </div>
  )
}
