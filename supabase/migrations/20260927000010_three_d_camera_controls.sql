-- The 3D viewer's camera-controls preference follows the account like the
-- other 3D settings (zoom, character).
alter table public.profiles
  add column if not exists three_d_camera_controls boolean not null default true;
