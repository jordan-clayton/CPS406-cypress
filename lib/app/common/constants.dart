const double torontoLat = 43.651070;
const double torontoLong = -79.347015;
// in kilometers
const torontoRadius = 20.0;
// in kilometers
// tweak as necessary
const locationDistanceThreshold = 1.0;

const double epsilon = 4.94065645841247E-324;
// in kilometers
const double haversine = 6371;

// Weighting factors to control the comparison.
const num categoryScore = 0.2;
const num closeToScore = 0.1;
const num frequencyWeight = 0.7;

/// Pass these in as command line arguments, or store accordingly
/// It's not imperative that these remain hidden, but it would be good to
/// keep them out of the commit history
const supabaseAnonKey = '';
const supabaseURL = '';
