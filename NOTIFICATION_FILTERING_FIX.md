# Notification Filtering Fix

## Problem
Users were receiving notifications for weather alerts issued in neighboring counties, even though the alerts didn't apply to their specific location. This was happening because the notification system was using distance-based filtering with relatively large radii (75-150km), which could span multiple counties.

## Root Cause
The `isLocationInAlertArea` function in `functions/src/index.ts` was prioritizing distance-based filtering over county-based filtering. The distance thresholds were too generous:
- Warnings: 75km radius
- Watches: 150km radius  
- Other alerts: 100km radius

## Solution Implemented

### 1. Prioritized County-Based Filtering
The filtering logic now follows this priority order:

1. **Method 1**: Check if user is within the actual alert polygon (most accurate)
2. **Method 2**: County-based filtering using area description (most reliable for county boundaries)
3. **Method 3**: Conservative distance-based fallback (only for alerts without geometry or area description)

### 2. Enhanced County Matching
Improved the `_isLocationInAreaDescription` function to handle:
- Direct county name matches
- "County" suffix variations
- Abbreviated county names
- State-wide alerts (more conservative approach)

### 3. Reduced Distance Thresholds
Significantly reduced the distance-based filtering thresholds:
- **Warnings**: 75km → 25km radius (67% reduction)
- **Watches**: 150km → 50km radius (67% reduction)
- **Other alerts**: 100km → 35km radius (65% reduction)

### 4. Enhanced Logging
Added comprehensive logging to help monitor and debug the filtering process:
- Alert summary statistics
- User location tracking
- County matching details
- Notification delivery status

## Technical Details

### Files Modified
- `functions/src/index.ts`: Main filtering logic and notification processing

### Key Functions Updated
- `isLocationInAlertArea()`: Reordered filtering methods and reduced distance thresholds
- `_isLocationInAreaDescription()`: Enhanced county matching with variations
- `sendNotificationsForAlert()`: Added detailed logging and statistics

### County Mapping
The system uses a comprehensive mapping of South Dakota cities and their associated counties:
```typescript
const sdLocations: { [key: string]: { lat: number, lon: number, counties: string[] } } = {
  'Sioux Falls': { lat: 43.5446, lon: -96.7311, counties: ['Minnehaha', 'Lincoln'] },
  'Rapid City': { lat: 44.0805, lon: -103.2310, counties: ['Pennington'] },
  // ... 50+ cities with county mappings
};
```

## Expected Results

### Before Fix
- Users in Minnehaha County receiving notifications for alerts in Lincoln County
- Users in Rapid City receiving notifications for alerts in neighboring counties
- Distance-based filtering causing cross-county notifications

### After Fix
- Users only receive notifications for alerts that specifically include their county
- County-based filtering takes priority over distance-based filtering
- Much more conservative distance thresholds for edge cases
- Better handling of state-wide alerts

## Monitoring

The enhanced logging will help monitor:
- How many users are in alert areas vs. how many receive notifications
- Which filtering method is being used for each alert
- County matching success rates
- Distance-based fallback usage

## Deployment Status
✅ **Deployed**: The updated functions have been successfully deployed to Firebase Functions.

## Testing Recommendations

1. **Monitor logs** for the next few days to verify filtering behavior
2. **Test with different alert types** (warnings, watches, advisories)
3. **Verify county-specific alerts** are being delivered correctly
4. **Check that cross-county notifications** are no longer occurring

## Future Enhancements

1. **Dynamic county mapping**: Consider updating county mappings based on user feedback
2. **Alert severity weighting**: Different filtering rules for different alert severities
3. **User preference overrides**: Allow users to adjust their notification radius
4. **Geographic boundary API**: Integrate with official county boundary APIs for more precise filtering 