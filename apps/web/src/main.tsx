import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.tsx'
import './index.css'

// Initialize Telegram Web App
declare global {
  interface Window {
    Telegram: {
      WebApp: any
    }
  }
}

// Expand the Mini App to full height
if (window.Telegram?.WebApp) {
  window.Telegram.WebApp.ready()
  window.Telegram.WebApp.expand()
  
  // Set header color
  window.Telegram.WebApp.setHeaderColor('bg_color')
  
  // Enable closing confirmation (optional)
  window.Telegram.WebApp.enableClosingConfirmation()
}

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
