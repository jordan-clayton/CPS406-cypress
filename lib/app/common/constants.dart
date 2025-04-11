const double torontoLat = 43.651070;
const double torontoLong = -79.347015;
// in kilometers
const torontoRadius = 20.0;
// in kilometers
// tweak as necessary
// Currently set to 10 meters
const locationDistanceThreshold = 10.0 / 1000;

const double epsilon = 4.94065645841247E-324;
// in kilometers
const double haversine = 6371;

// Weighting factors to control the comparison.
const num categoryScore = 0.35;
const num closeToScore = 0.1;
const num frequencyWeight = 0.55;

const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZuZHR0Z3ZzcGpmdWthamd3anBvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQwNzE3NDUsImV4cCI6MjA1OTY0Nzc0NX0.A2G57hgH-qooC0ICQfw2uc7gXz9caEB4eqnd_ydQCmo';
const supabaseURL = 'https://fndttgvspjfukajgwjpo.supabase.co';
