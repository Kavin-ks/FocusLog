-- Add name and email to users table
ALTER TABLE users ADD COLUMN name TEXT;
ALTER TABLE users ADD COLUMN email TEXT UNIQUE;

-- Make email required for new signups (existing users can have null)
-- For existing users, we can assume they need to update or something, but for now, allow null