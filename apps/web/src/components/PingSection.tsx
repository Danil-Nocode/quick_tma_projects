import { useState } from 'react'

interface PingSectionProps {
  initData: string
  apiBaseUrl: string
  apiStatus: 'checking' | 'online' | 'offline'
}

export const PingSection = ({ initData, apiBaseUrl, apiStatus }: PingSectionProps) => {
  const [loading, setLoading] = useState(false)
  const [response, setResponse] = useState<any>(null)
  const [error, setError] = useState<string | null>(null)

  const handlePing = async () => {
    if (!initData) {
      setError('InitData недоступен. Откройте приложение через Telegram бота.')
      return
    }

    setLoading(true)
    setError(null)
    setResponse(null)

    try {
      const pingResponse = await fetch(`${apiBaseUrl}/api/ping`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          initData: initData
        })
      })

      const data = await pingResponse.json()

      if (pingResponse.ok) {
        setResponse(data)
      } else {
        setError(data.error || 'API request failed')
      }
    } catch (err) {
      console.error('Ping error:', err)
      setError(err instanceof Error ? err.message : 'Network error')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="ping-section">
      <button 
        className="button" 
        onClick={handlePing}
        disabled={loading || apiStatus === 'offline' || !initData}
      >
        {loading ? (
          <>
            <div className="loading"></div>
            Отправка запроса...
          </>
        ) : (
          '🏓 Ping API'
        )}
      </button>

      {apiStatus === 'offline' && (
        <div className="response-card error">
          <p>❌ API недоступен</p>
          <p>Проверьте подключение к серверу</p>
        </div>
      )}

      {!initData && apiStatus === 'online' && (
        <div className="response-card error">
          <p>⚠️ InitData недоступен</p>
          <p>Откройте приложение через Telegram бота для получения данных авторизации</p>
        </div>
      )}

      {error && (
        <div className="response-card error">
          <h4>❌ Ошибка</h4>
          <p>{error}</p>
        </div>
      )}

      {response && (
        <div className="response-card success">
          <h4>✅ Ответ от сервера</h4>
          <p><strong>Статус:</strong> {response.status}</p>
          <p><strong>Сообщение:</strong> {response.message}</p>
          {response.user && (
            <div style={{ marginTop: '12px' }}>
              <p><strong>Пользователь подтверждён:</strong></p>
              <p>• ID: {response.user.id}</p>
              <p>• Имя: {response.user.first_name} {response.user.last_name}</p>
              {response.user.username && <p>• Username: @{response.user.username}</p>}
            </div>
          )}
          <pre>{JSON.stringify(response, null, 2)}</pre>
        </div>
      )}
    </div>
  )
}
