-- Basic schema to be migrated/used in our backend solution

-- If we use supabase/postress, run this script to set up the database.

-- TODO: create proper enumerated types
CREATE TYPE problem_category as ENUM ('crime', 'fire', 'water', 'infrastructure');
CREATE TYPE progress as ENUM ('opened', 'in-progress', 'closed');
CREATE TYPE notifcation_type as ENUM ('sms', 'email', 'push')

-- TODO: server-side validation for email/phone.
CREATE TABLE public.profiles (
    id uuid NOT NULL,
    username text NOT NULL DEFAULT "anon",
    -- Not sure if we're using FCM for push notifications.
    -- This should be encrypted regardless.
    fcm_token text,
    email text,
    phone text,

    PRIMARY KEY (id)
    FOREIGN KEY (id) REFERENCES auth.users ON DELETE CASCADE,
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
