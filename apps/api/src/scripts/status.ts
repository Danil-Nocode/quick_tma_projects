import 'dotenv/config'
import { supabase } from '../lib/supabase.js'

async function checkDatabaseStatus() {
  try {
    console.log('🔍 Checking database status...')

    // Test connection
    const { data: connectionTest, error: connectionError } = await supabase
      .from('profiles')
      .select('count')
      .limit(1)

    if (connectionError) {
      throw connectionError
    }

    console.log('✅ Database connection: OK')

    // Get profiles count
    const { count, error: countError } = await supabase
      .from('profiles')
      .select('*', { count: 'exact', head: true })

    if (countError) {
      throw countError
    }

    console.log(`📊 Total profiles: ${count || 0}`)

    // Get recent profiles
    const { data: recentProfiles, error: recentError } = await supabase
      .from('profiles')
      .select('tg_id, username, first_name, created_at')
      .order('created_at', { ascending: false })
      .limit(5)

    if (recentError) {
      throw recentError
    }

    if (recentProfiles && recentProfiles.length > 0) {
      console.log('\n📋 Recent profiles:')
      recentProfiles.forEach((profile) => {
        console.log(`  • ${profile.first_name || 'Unknown'} (@${profile.username || 'no-username'}) - ID: ${profile.tg_id}`)
      })
    }

    console.log('\n✅ Database status check completed!')
    
  } catch (error) {
    console.error('❌ Database status check failed:', error)
    process.exit(1)
  }
}

// Run status check if this script is executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
  checkDatabaseStatus()
}
