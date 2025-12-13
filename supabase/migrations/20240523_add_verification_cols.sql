-- Add verification columns to activities table
ALTER TABLE public.activities 
ADD COLUMN IF NOT EXISTS is_verified boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS verification_data jsonb;

COMMENT ON COLUMN public.activities.is_verified IS 'Whether the activity was verified by AI or other means';
COMMENT ON COLUMN public.activities.verification_data IS 'JSONB blob containing full verification details (confidence, reasoning, etc)';
