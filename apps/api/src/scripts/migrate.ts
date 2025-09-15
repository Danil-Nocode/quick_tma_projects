import 'dotenv/config'
import { supabase } from '../lib/supabase.js'

async function runMigrations() {
  try {
    console.log('🚀 Running database migrations...')

    // Create profiles table
    const { error: profilesError } = await supabase.rpc('exec_sql', {
      sql: `
        CREATE TABLE IF NOT EXISTS profiles (
          id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
          tg_id BIGINT UNIQUE NOT NULL,
          username TEXT,
          first_name TEXT,
          last_name TEXT,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE
        );

        -- Create index on tg_id for faster lookups
        CREATE INDEX IF NOT EXISTS idx_profiles_tg_id ON profiles(tg_id);
        
        -- Create updated_at trigger
        CREATE OR REPLACE FUNCTION update_updated_at_column()
        RETURNS TRIGGER AS $$
        BEGIN
          NEW.updated_at = NOW();
          RETURN NEW;
        END;
        $$ language 'plpgsql';

        DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
        CREATE TRIGGER update_profiles_updated_at
          BEFORE UPDATE ON profiles
          FOR EACH ROW
          EXECUTE FUNCTION update_updated_at_column();

        -- Enable RLS (Row Level Security)
        ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
        
        -- Create policy for service role (full access)
        DROP POLICY IF EXISTS "Service role can do everything" ON profiles;
        CREATE POLICY "Service role can do everything" ON profiles
          FOR ALL USING (auth.role() = 'service_role');
      `
    })

    if (profilesError) {
      throw profilesError
    }

    console.log('✅ Database migrations completed successfully!')
    
    // Test the table
    const { data, error: testError } = await supabase
      .from('profiles')
      .select('count')
      .limit(1)

    if (testError) {
      throw testError
    }

    console.log('✅ Database connection verified!')
    
  } catch (error) {
    console.error('❌ Migration failed:', error)
    process.exit(1)
  }
}

// Run migrations if this script is executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
  runMigrations()
}
