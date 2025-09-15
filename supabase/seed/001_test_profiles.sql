-- Test data for profiles table
-- This is optional seed data for development/testing

INSERT INTO profiles (tg_id, username, first_name, last_name) VALUES
(123456789, 'testuser1', 'Test', 'User'),
(987654321, 'demo_user', 'Demo', 'Account'),
(555666777, 'john_doe', 'John', 'Doe')
ON CONFLICT (tg_id) DO UPDATE SET
  username = EXCLUDED.username,
  first_name = EXCLUDED.first_name,
  last_name = EXCLUDED.last_name,
  updated_at = NOW();
