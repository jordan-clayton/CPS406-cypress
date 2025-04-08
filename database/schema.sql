-- Basic schema to be migrated/used in our backend solution
-- If we use supabase/postress, run this script to set up the database.

-- TODO: create proper enumerated types
CREATE TYPE problem_category as ENUM ('crime', 'fire', 'water', 'infrastructure');
CREATE TYPE progress as ENUM ('opened', 'in-progress', 'closed');
CREATE TYPE notification_type as ENUM ('sms', 'email', 'push');
CREATE TYPE duplicate_severity as ENUM ('unlikely', 'possible', 'suspected', 'confirmed');
CREATE TYPE flagged_reason as ENUM ('malicious', 'false-report', 'ambiguous', 'non-emergency');
-- TODO: implement some sort of levels of privilege type deal?
CREATE TYPE auth as ENUM ('l2', 'l1', 'l0');

-- TODO: server-side validation for email/phone.
CREATE TABLE public.profiles (
    id uuid NOT NULL,
    username text NOT NULL DEFAULT "anon",
    -- Not sure if we're using FCM for push notifications.
    -- This should be encrypted regardless.
    fcm_token text,
    email text,
    phone text,

    FOREIGN KEY (id) REFERENCES auth.users ON DELETE CASCADE,
    PRIMARY KEY (id)
);

CREATE TABLE employees (
    id uuid NOT NULL,
    first_name text,
    last_name text,
    employee_id bigint NOT NULL,
    authority auth,
    FOREIGN KEY (id) REFERENCES auth.users (id) ON DELETE CASCADE,
    PRIMARY KEY (id, employee_id)
);

CREATE TABLE reports (
    id bigint NOT NULL AUTO_INCREMENT,
    category problem_category NOT NULL,
    -- We could go with numeric for 131072 digits of precision
    -- double precision is 15 digits, likely all we need
    latitude double precision,
    longitude double precision,
    description text,
    verified boolean,
    progress progress,
    -- If/when we eventually add compressed images, this 
    -- table will need a file-descriptor to locate it
    PRIMARY KEY (id)
);

CREATE TABLE subscriptions (
    user_id uuid,
    report_id bigint,
    method notification_type,
    FOREIGN KEY (user_id) REFERENCES public.profiles (id) ON DELETE CASCADE,
    FOREIGN KEY (report_id) REFERENCES reports (id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, report_id, method)
);

create TABLE duplicates (
    report_id bigint,
    match_id bigint,
    severity duplicate_severity,

    FOREIGN KEY (report_id) REFERENCES reports (id) ON DELETE CASCADE,
    FOREIGN KEY (match_id) REFERENCES reports (id) ON DELETE CASCADE,
    PRIMARY KEY (report_id, match_id)
);

create TABLE flagged(
    report_id bigint,
    reason flagged_reason,
    FOREIGN KEY (report_id) REFERENCES reports (id) ON DELETE CASCADE,
    PRIMARY KEY (report_id, reason)
);