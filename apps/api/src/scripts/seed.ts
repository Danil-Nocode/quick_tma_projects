import 'dotenv/config'
import { supabase } from '../lib/supabase.js'

async function seedDatabase() {
  try {
    console.log('🌱 Seeding database...')

    // Check if we already have data
    const { data: existingProfiles, error: checkError } = await supabase
      .from('profiles')
      .select('count')

    if (checkError) {
      throw checkError
    }

    if (existingProfiles && existingProfiles.length > 0) {
      console.log('📊 Database already has data, skipping seed...')
      return
    }

    // Add some example profiles (you can remove this in production)
    const seedData = [
      {
        tg_id: 123456789,
        username: 'testuser1',
        first_name: 'Test',
        last_name: 'User'
      },
      {
        tg_id: 987654321,
        username: 'testuser2',
        first_name: 'Demo',
        last_name: 'Account'
      }
    ]

    const { error: insertError } = await supabase
      .from('profiles')
      .insert(seedData)

    if (insertError) {
      throw insertError
    }

    console.log('✅ Database seeded successfully!')
    console.log(`📊 Added ${seedData.length} test profiles`)
    
  } catch (error) {
    console.error('❌ Seed failed:', error)
    process.exit(1)
  }
}

// Run seed if this script is executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
  seedDatabase()
}
