-- The white and blue interface is the product identity, so a fresh profile
-- starts on the light theme instead of following the operating system, which
-- hid it from anyone whose machine prefers dark.
ALTER TABLE public.profiles ALTER COLUMN theme SET DEFAULT 'light';

-- Existing rows still holding the former default never expressed a choice.
UPDATE public.profiles SET theme = 'light' WHERE theme = 'system';
