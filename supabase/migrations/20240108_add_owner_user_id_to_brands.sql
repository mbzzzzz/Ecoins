-- Add owner_user_id column to brands table
-- This fixes the mismatch between code (expects owner_user_id) and database (has user_id)

-- Add owner_user_id column if it doesn't exist
ALTER TABLE public.brands 
ADD COLUMN IF NOT EXISTS owner_user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE;

-- Copy data from user_id to owner_user_id if user_id exists and owner_user_id is null
UPDATE public.brands 
SET owner_user_id = user_id 
WHERE owner_user_id IS NULL AND user_id IS NOT NULL;

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_brands_owner_user_id ON public.brands(owner_user_id);

-- Update RLS policies to use owner_user_id
DROP POLICY IF EXISTS "Brand owners can manage their brands" ON public.brands;
CREATE POLICY "Brand owners can manage their brands" ON public.brands
  FOR ALL USING (auth.uid() = owner_user_id);

-- Also ensure brands are viewable by everyone
DROP POLICY IF EXISTS "Brands are viewable by everyone" ON public.brands;
CREATE POLICY "Brands are viewable by everyone" ON public.brands
  FOR SELECT USING (true);

