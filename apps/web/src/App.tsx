import { useState, useEffect } from 'react'
import { useTelegram } from './hooks/useTelegram'
import { UserInfo } from './components/UserInfo'
import { PingSection } from './components/PingSection'

const API_BASE_URL = import.meta.env.PROD 
  ? `https://${import.meta.env.VITE_API_DOMAIN || window.location.hostname}`
  : 'http://localhost:3001'

function App() {
  const { webApp, user, initData } = useTelegram()
  const [apiStatus, setApiStatus] = useState<'checking' | 'online' | 'offline'>('checking')

  // Check API health on mount
  useEffect(() => {
    const checkApiHealth = async () => {
      try {
        const response = await fetch(`${API_BASE_URL}/api/health`)
        if (response.ok) {
          setApiStatus('online')
        } else {
          setApiStatus('offline')
        }
      } catch (error) {
        console.error('API health check failed:', error)
        setApiStatus('offline')
      }
    }

    checkApiHealth()

    // Recheck every 30 seconds
    const interval = setInterval(checkApiHealth, 30000)
    return () => clearInterval(interval)
  }, [])

  return (
    <div className="container">
      <div className="header">
        <h1>🚀 Telegram Mini App</h1>
        <p>
          Powered by React + Supabase
          <span className={`status-badge ${apiStatus}`}>
            {apiStatus === 'checking' ? '⏳' : apiStatus === 'online' ? '🟢' : '🔴'} API
          </span>
        </p>
      </div>

      <UserInfo 
        user={user} 
        webApp={webApp}
        initDataAvailable={!!initData}
      />

      <PingSection
        initData={initData}
        apiBaseUrl={API_BASE_URL}
        apiStatus={apiStatus}
      />

      <div className="footer">
        <p>
          {webApp?.platform ? `Platform: ${webApp.platform}` : 'Running in browser'} • 
          Version: {webApp?.version || 'Unknown'}
        </p>
      </div>
    </div>
  )
}

export default App
