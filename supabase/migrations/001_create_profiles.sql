-- Create profiles table for Telegram users
CREATE TABLE profiles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  tg_id BIGINT UNIQUE NOT NULL,
  username TEXT,
  first_name TEXT,
  last_name TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE
);

-- Create index on tg_id for faster lookups
CREATE INDEX idx_profiles_tg_id ON profiles(tg_id);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for updated_at
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create policy for service role (full access)
CREATE POLICY "Service role can do everything" ON profiles
  FOR ALL USING (auth.role() = 'service_role');

-- Create policy for authenticated users (can only see their own profile)
CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT USING (auth.uid()::text = tg_id::text);

-- Create policy for users to update their own profile
CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid()::text = tg_id::text);

-- Comments for documentation
COMMENT ON TABLE profiles IS 'User profiles linked to Telegram accounts';
COMMENT ON COLUMN profiles.id IS 'Primary key UUID';
COMMENT ON COLUMN profiles.tg_id IS 'Telegram user ID (unique)';
COMMENT ON COLUMN profiles.username IS 'Telegram username (without @)';
COMMENT ON COLUMN profiles.first_name IS 'Telegram first name';
COMMENT ON COLUMN profiles.last_name IS 'Telegram last name';
COMMENT ON COLUMN profiles.created_at IS 'Profile creation timestamp';
COMMENT ON COLUMN profiles.updated_at IS 'Profile last update timestamp';
