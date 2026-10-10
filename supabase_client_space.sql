-- ============================================================================
--  Aeternum Works — Client Space schema
--  Run in: Supabase Dashboard → SQL Editor → New query → Run
--  Safe to run more than once (idempotent).
-- ============================================================================

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- settings  (restores the missing key/value table used by admin.html)
-- ---------------------------------------------------------------------------
create table if not exists public.settings (
  id    bigserial primary key,
  key   text unique not null,
  value text
);

-- ---------------------------------------------------------------------------
-- client_tasks  (the checklist: Session -> Week(phase) -> Task)
-- ---------------------------------------------------------------------------
create table if not exists public.client_tasks (
  id          uuid primary key default gen_random_uuid(),
  client_id   text not null,                         -- e.g. 'envirosystech'
  session     text,                                  -- top group, e.g. 'Session 1 — Weeks 1–2'
  phase       text not null,                         -- the "week", e.g. 'Week 1 — Content, Pages & Link Completion'
  title       text not null,
  description text,
  status      text not null default 'pending',       -- pending | in_progress | done | blocked
  sort_order  integer not null default 0,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- client_comments
--   scope is decided by which keys are set:
--     task_id set               -> task comment
--     phase set, no task_id     -> week comment
--     session set, no phase     -> session comment
--     none set                  -> general comment
-- ---------------------------------------------------------------------------
create table if not exists public.client_comments (
  id         uuid primary key default gen_random_uuid(),
  client_id  text not null,
  session    text,
  phase      text,
  task_id    uuid references public.client_tasks(id) on delete cascade,
  author     text not null default 'Client',
  body       text not null,
  created_at timestamptz not null default now()
);

-- bring older installations up to date (no-op on a fresh run)
alter table public.client_tasks    add column if not exists session text;
alter table public.client_comments add column if not exists session text;
alter table public.client_comments add column if not exists phase   text;

create index if not exists client_tasks_client_idx    on public.client_tasks (client_id, sort_order);
create index if not exists client_comments_client_idx on public.client_comments (client_id, created_at);

-- ---------------------------------------------------------------------------
-- Row Level Security
--   The console talks to Supabase with the anon key, so anon needs access.
--   NOTE: this means anyone holding the anon key can read/write these rows.
--   The page is still gated by the client password, but for anything
--   sensitive, move to Supabase Auth + per-user policies later.
-- ---------------------------------------------------------------------------
alter table public.settings        enable row level security;
alter table public.client_tasks    enable row level security;
alter table public.client_comments enable row level security;

drop policy if exists settings_all on public.settings;
create policy settings_all on public.settings
  for all using (true) with check (true);

drop policy if exists client_tasks_all on public.client_tasks;
create policy client_tasks_all on public.client_tasks
  for all using (true) with check (true);

drop policy if exists client_comments_all on public.client_comments;
create policy client_comments_all on public.client_comments
  for all using (true) with check (true);

-- Explicit grants so the anon key can actually use the new tables/sequences
grant usage on schema public to anon, authenticated;
grant all privileges on public.settings        to anon, authenticated;
grant all privileges on public.client_tasks    to anon, authenticated;
grant all privileges on public.client_comments to anon, authenticated;
grant all privileges on all sequences in schema public to anon, authenticated;

-- ---------------------------------------------------------------------------
-- updated_at trigger for tasks
-- ---------------------------------------------------------------------------
create or replace function public.touch_updated_at() returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists client_tasks_touch on public.client_tasks;
create trigger client_tasks_touch
  before update on public.client_tasks
  for each row execute function public.touch_updated_at();

-- ============================================================================
--  SEED — Envirosys Technologies, LLC  (client_id = 'envirosystech')
-- ============================================================================
delete from public.client_tasks where client_id = 'envirosystech';

insert into public.client_tasks (client_id, session, phase, title, description, status, sort_order) values

-- ── Session 1 · Weeks 1–2 ──────────────────────────────────────────────────
('envirosystech','Session 1 — Weeks 1–2','Week 1 — Content, Pages & Link Completion','Full website audit & issue register','30 issues verified live across navigation, site configuration, content and technical SEO.', 'done', 10),
('envirosystech','Session 1 — Weeks 1–2','Week 1 — Content, Pages & Link Completion','Fix footer navigation links','Repoint the 5 wrong footer links (/civil, /construction, /sustainability, /energy-efficiency, /new-page) to the correct page URLs.', 'in_progress', 20),
('envirosystech','Session 1 — Weeks 1–2','Week 1 — Content, Pages & Link Completion','Footer "Services" link + services page','Make "Services" a real link, unlock the password-protected /services page and resolve the /services-1 redirect.', 'pending', 30),
('envirosystech','Session 1 — Weeks 1–2','Week 1 — Content, Pages & Link Completion','Build Services page content','The /services page is empty. Add hub content: intro + a short section and "Learn More" button for each service area. Copy drafted in Envirosys_New_Page_Content_Services.md.', 'pending', 35),
('envirosystech','Session 1 — Weeks 1–2','Week 1 — Content, Pages & Link Completion','Fix empty "Contact Us" buttons','4 empty buttons on Environmental & Sustainability + 2 more on the About page → point them all to /contact.', 'pending', 40),
('envirosystech','Session 1 — Weeks 1–2','Week 1 — Content, Pages & Link Completion','Build missing page: Health & Specialized Development','The page is referenced in the menu and Contact page but returns 404. Copy is drafted and ready to paste.', 'pending', 50),
('envirosystech','Session 1 — Weeks 1–2','Week 1 — Content, Pages & Link Completion','Fix typos & formatting','"Technoligies" → Technologies; remove the duplicated "enabling resilient ecosystems"; fix "in** **AI"; add the missing spaces after periods.', 'pending', 60),
('envirosystech','Session 1 — Weeks 1–2','Week 1 — Content, Pages & Link Completion','Fix footer copy & logo alt text','Add the missing comma ("engineering, energy") and set the footer logo alt text.', 'pending', 70),
('envirosystech','Session 1 — Weeks 1–2','Week 1 — Content, Pages & Link Completion','Correct duplicate & mismatched headings','Contact page duplicate H1; near-identical homepage headings; Engineering page headings reordered to match their content.', 'pending', 80),
('envirosystech','Session 1 — Weeks 1–2','Week 1 — Content, Pages & Link Completion','Replace footer logo','The current footer logo is imported from a different Squarespace site — re-upload the correct one.', 'pending', 90),
('envirosystech','Session 1 — Weeks 1–2','Week 1 — Content, Pages & Link Completion','Standardize page naming','Use one name everywhere: "Specialized Consulting & Training".', 'pending', 100),
('envirosystech','Session 1 — Weeks 1–2','Week 1 — Content, Pages & Link Completion','Update images on the Services page','Replace the repeated stock image in each /services section with distinct, relevant images (ideally real Envirosys imagery).', 'pending', 102),
('envirosystech','Session 1 — Weeks 1–2','Week 1 — Content, Pages & Link Completion','Update images on the Health page','Add or replace images on the Health & Specialized Development page once it is built.', 'pending', 104),
('envirosystech','Session 1 — Weeks 1–2','Week 2 — Technical SEO Foundation','Fix region / country / time zone','Currently set to Pakistan / Punjab / Asia-Karachi. Change to United States / Maryland / Eastern Time.', 'pending', 110),
('envirosystech','Session 1 — Weeks 1–2','Week 2 — Technical SEO Foundation','Add Organization + LocalBusiness schema','Add JSON-LD structured data via Code Injection (requires the Core plan or higher).', 'pending', 120),
('envirosystech','Session 1 — Weeks 1–2','Week 2 — Technical SEO Foundation','Set up Google Analytics 4','Add the GA4 measurement ID via the built-in integration.', 'pending', 130),
('envirosystech','Session 1 — Weeks 1–2','Week 2 — Technical SEO Foundation','Fix social media links','All 4 icons point at platform homepages — replace with the real company profiles.', 'pending', 140),
('envirosystech','Session 1 — Weeks 1–2','Week 2 — Technical SEO Foundation','Clean URLs & redirects','Tidy up slugs and make sure every redirect lands on the right page.', 'pending', 150),
('envirosystech','Session 1 — Weeks 1–2','Week 2 — Technical SEO Foundation','Sitemap & Search Console','Sitemap is auto-generated — submit it to Google Search Console and monitor indexing.', 'pending', 160),
('envirosystech','Session 1 — Weeks 1–2','Week 2 — Technical SEO Foundation','Make the Services menu item clickable','Clicking ''Services'' in the top menu should open the /services page, while hovering still reveals the service sub-links. Squarespace 7.1 folder titles are not clickable by design. Fix options: (a) a small Code Injection snippet (needs Core plan or higher), or (b) add a ''Services overview'' link as the first item inside the dropdown (works on any plan).', 'pending', 165),
('envirosystech','Session 1 — Weeks 1–2','Week 2 — Technical SEO Foundation','Page speed & mobile review','Check performance and mobile experience, fix what slows the site down.', 'pending', 170),
('envirosystech','Session 1 — Weeks 1–2','Week 2 — Technical SEO Foundation','Add ad / promo videos','Client wants to add promo/ad videos in place of some images. Use Video blocks (click-to-play) or background video where appropriate; embed via YouTube/Vimeo for longer clips to protect page speed.', 'pending', 175),

-- ── Session 2 · Weeks 3–4 ──────────────────────────────────────────────────
('envirosystech','Session 2 — Weeks 3–4','Week 3 — On-Page Optimization','Keyword research','Research keywords for the consulting / engineering / AI niche and service areas.', 'pending', 180),
('envirosystech','Session 2 — Weeks 3–4','Week 3 — On-Page Optimization','Optimize title tags & meta descriptions','Rewrite the title and meta description on every page.', 'pending', 190),
('envirosystech','Session 2 — Weeks 3–4','Week 3 — On-Page Optimization','Heading hierarchy & keyword placement','Put keywords in headings and fix the H1 → H2 → H3 structure.', 'pending', 200),
('envirosystech','Session 2 — Weeks 3–4','Week 3 — On-Page Optimization','Internal linking structure','Link related pages together so every page connects.', 'pending', 210),
('envirosystech','Session 2 — Weeks 3–4','Week 3 — On-Page Optimization','Image alt-text optimization','Add descriptive alt text to all meaningful images.', 'pending', 220),
('envirosystech','Session 2 — Weeks 3–4','Week 3 — On-Page Optimization','Content quality pass','Tighten and improve the wording across the site.', 'pending', 230),
('envirosystech','Session 2 — Weeks 3–4','Week 4 — Local SEO & Content','Google Business Profile setup','Create and optimize the profile for Gaithersburg, MD.', 'pending', 240),
('envirosystech','Session 2 — Weeks 3–4','Week 4 — Local SEO & Content','NAP consistency & citations','Make name, address and phone consistent across directories.', 'pending', 250),
('envirosystech','Session 2 — Weeks 3–4','Week 4 — Local SEO & Content','MBE / SBE / DBE trust signals','Surface the certifications as trust signals on the site.', 'pending', 260),
('envirosystech','Session 2 — Weeks 3–4','Week 4 — Local SEO & Content','Keyword-to-page mapping','Map each target keyword to the page that should rank for it.', 'pending', 270),
('envirosystech','Session 2 — Weeks 3–4','Week 4 — Local SEO & Content','Service page optimization','Optimize each service page for its target terms.', 'pending', 280),
('envirosystech','Session 2 — Weeks 3–4','Week 4 — Local SEO & Content','Content roadmap','Plan the content that will grow search traffic over time.', 'pending', 290),

-- ── Session 3 · Week 5 ─────────────────────────────────────────────────────
('envirosystech','Session 3 — Week 5','Week 5 — Off-Page, Reporting & Handover','Backlink opportunity research','Find relevant sites and directories to earn links from.', 'pending', 300),
('envirosystech','Session 3 — Week 5','Week 5 — Off-Page, Reporting & Handover','Directory & citation submissions','Submit the business to relevant directories.', 'pending', 310),
('envirosystech','Session 3 — Week 5','Week 5 — Off-Page, Reporting & Handover','Search Console + Analytics dashboards','Set up the reporting dashboards.', 'pending', 320),
('envirosystech','Session 3 — Week 5','Week 5 — Off-Page, Reporting & Handover','Baseline ranking & performance report','Record the starting position to measure progress against.', 'pending', 330),
('envirosystech','Session 3 — Week 5','Week 5 — Off-Page, Reporting & Handover','Final before / after audit','Deliver the completed audit document.', 'pending', 340),
('envirosystech','Session 3 — Week 5','Week 5 — Off-Page, Reporting & Handover','Handover session & documentation','Walk the client through everything and hand over the docs.', 'pending', 350);

-- ============================================================================
--  Done. Refresh clients.html — the Envirosys workspace shows Session ->
--  Week -> Task, each with its own comment box.
-- ============================================================================
