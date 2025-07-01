/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import {setGlobalOptions} from "firebase-functions";
// Import v1 functions for schedule
import * as functions from "firebase-functions/v1";
// Use require for node-fetch to avoid type issues
const fetch = require("node-fetch");
import * as admin from "firebase-admin";

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({maxInstances: 10});

admin.initializeApp();

const RELEVANT_ALERT_TYPES = [
  "Air Quality Alert",
  "Air Stagnation Advisory",
  "Blizzard Warning",
  "Blowing Dust Advisory",
  "Blowing Dust Warning",
  "Brisk Wind Advisory",
  "Cold Weather Advisory",
  "Dense Fog Advisory",
  "Dense Smoke Advisory",
  "Dust Advisory",
  "Dust Storm Warning",
  "Evacuation Immediate",
  "Extreme Heat Warning",
  "Extreme Heat Watch",
  "Extreme Cold Warning",
  "Extreme Cold Watch",
  "Extreme Fire Danger",
  "Extreme Wind Warning",
  "Fire Warning",
  "Fire Weather Watch",
  "Flash Flood Statement",
  "Flash Flood Warning",
  "Flash Flood Watch",
  "Flood Advisory",
  "Flood Statement",
  "Flood Warning",
  "Flood Watch",
  "Freeze Warning",
  "Freeze Watch",
  "Freezing Fog Advisory",
  "Frost Advisory",
  "Heat Advisory",
  "High Wind Warning",
  "High Wind Watch",
  "Ice Storm Warning",
  "Law Enforcement Warning",
  "Local Area Emergency",
  "Red Flag Warning",
  "Severe Thunderstorm Warning",
  "Severe Thunderstorm Watch",
  "Severe Weather Statement",
  "Shelter In Place Warning",
  "Snow Squall Warning",
  "Special Weather Statement",
  "Tornado Warning",
  "Tornado Watch",
  "Wind Advisory",
  "Winter Storm Warning",
  "Winter Storm Watch",
  "Winter Weather Advisory"
];

function calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371; // Earth's radius in kilometers
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = 
    Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * 
    Math.sin(dLon/2) * Math.sin(dLon/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return R * c;
}

// Check if a point is inside a polygon using ray casting algorithm
function isPointInPolygon(point: [number, number], polygon: number[][]): boolean {
  const [x, y] = point;
  let inside = false;
  
  for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    const [xi, yi] = polygon[i];
    const [xj, yj] = polygon[j];
    
    if (((yi > y) !== (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi)) {
      inside = !inside;
    }
  }
  
  return inside;
}

function isLocationInAlertArea(userLat: number, userLon: number, alertGeometry: any, alertType?: string, areaDesc?: string): boolean {
  if (!alertGeometry) {
    console.log(`❌ No alert geometry provided`);
    
    // Method 3: Fallback to areaDesc parsing for alerts without geometry
    if (areaDesc) {
      console.log(`🔍 Attempting to match by area description: ${areaDesc}`);
      return _isLocationInAreaDescription(userLat, userLon, areaDesc);
    }
    
    console.log(`❌ No geometry or area description available`);
    return false;
  }
  
  console.log(`🔍 Checking location match for user at (${userLat}, ${userLon}) for ${alertType}`);
  console.log(`🗺️ Alert geometry type: ${alertGeometry.type}`);
  
  // Method 1: Check if user is within the actual alert polygon
  if (alertGeometry.type === 'Polygon' && alertGeometry.coordinates) {
    const polygon = alertGeometry.coordinates[0]; // First ring of the polygon
    console.log(`📍 Checking polygon with ${polygon.length} points`);
    
    if (isPointInPolygon([userLon, userLat], polygon)) {
      console.log(`✅ User is inside alert polygon`);
      return true;
    } else {
      console.log(`❌ User is outside alert polygon`);
    }
  }
  
  // Method 2: Check if user is within a reasonable distance of the alert center
  if (alertGeometry.coordinates) {
    // For polygon geometry, calculate the center
    let alertCenterLon, alertCenterLat;
    
    if (alertGeometry.type === 'Polygon' && alertGeometry.coordinates[0]) {
      const polygon = alertGeometry.coordinates[0];
      // Calculate centroid of polygon
      let sumLon = 0, sumLat = 0;
      for (const point of polygon) {
        sumLon += point[0];
        sumLat += point[1];
      }
      alertCenterLon = sumLon / polygon.length;
      alertCenterLat = sumLat / polygon.length;
    } else {
      // Assume it's a point geometry
      alertCenterLon = alertGeometry.coordinates[0];
      alertCenterLat = alertGeometry.coordinates[1];
    }
    
    console.log(`📍 Alert center at (${alertCenterLat}, ${alertCenterLon})`);
    const distance = calculateDistance(userLat, userLon, alertCenterLat, alertCenterLon);
    console.log(`📏 Distance from alert center: ${distance.toFixed(2)}km`);
    
    // Adjust distance threshold based on alert type
    let maxDistance: number;
    if (alertType && alertType.toLowerCase().includes('watch')) {
      // Watches typically cover larger areas - be more generous
      maxDistance = 150; // 150km radius for watches
      console.log(`👀 Watch alert detected - using ${maxDistance}km radius`);
    } else if (alertType && alertType.toLowerCase().includes('warning')) {
      // Warnings are more localized
      maxDistance = 75; // 75km radius for warnings
      console.log(`⚠️ Warning alert detected - using ${maxDistance}km radius`);
    } else {
      // Default for other alert types
      maxDistance = 100; // 100km radius for other alerts
      console.log(`📢 Other alert type - using ${maxDistance}km radius`);
    }
    
    const isWithinDistance = distance <= maxDistance;
    console.log(`🎯 Within ${maxDistance}km radius: ${isWithinDistance}`);
    
    return isWithinDistance;
  }
  
  console.log(`❌ No valid geometry coordinates found`);
  return false;
}

// Helper function to check if user is in the area based on areaDesc
function _isLocationInAreaDescription(userLat: number, userLon: number, areaDesc: string): boolean {
  // Define major South Dakota cities and their counties
  const sdLocations: { [key: string]: { lat: number, lon: number, counties: string[] } } = {
    'Sioux Falls': { lat: 43.5446, lon: -96.7311, counties: ['Minnehaha', 'Lincoln'] },
    'Rapid City': { lat: 44.0805, lon: -103.2310, counties: ['Pennington'] },
    'Aberdeen': { lat: 45.4647, lon: -98.4864, counties: ['Brown'] },
    'Brookings': { lat: 44.3114, lon: -96.7984, counties: ['Brookings'] },
    'Watertown': { lat: 44.9016, lon: -97.1151, counties: ['Codington'] },
    'Pierre': { lat: 44.3683, lon: -100.3510, counties: ['Hughes'] },
    'Yankton': { lat: 42.8711, lon: -97.3973, counties: ['Yankton'] },
    'Huron': { lat: 44.3633, lon: -98.2142, counties: ['Beadle'] },
    'Vermillion': { lat: 42.7794, lon: -96.9292, counties: ['Clay'] },
    'Mitchell': { lat: 43.7097, lon: -98.0298, counties: ['Davison'] },
    'Spearfish': { lat: 44.4908, lon: -103.8594, counties: ['Lawrence'] },
    'Sturgis': { lat: 44.4097, lon: -103.5091, counties: ['Meade'] },
    'Deadwood': { lat: 44.3767, lon: -103.7296, counties: ['Lawrence'] },
    'Lead': { lat: 44.3512, lon: -103.7652, counties: ['Lawrence'] },
    'Belle Fourche': { lat: 44.6714, lon: -103.8521, counties: ['Butte'] },
    'Hot Springs': { lat: 43.4316, lon: -103.4741, counties: ['Fall River'] },
    'Custer': { lat: 43.7694, lon: -103.6019, counties: ['Custer'] },
    'Keystone': { lat: 43.8961, lon: -103.4263, counties: ['Pennington'] },
    'Hill City': { lat: 43.9325, lon: -103.5749, counties: ['Pennington'] },
    'Madison': { lat: 44.0061, lon: -97.1139, counties: ['Lake'] },
    'Brandon': { lat: 43.5944, lon: -96.5717, counties: ['Minnehaha'] },
    'Harrisburg': { lat: 43.4316, lon: -96.6989, counties: ['Lincoln'] },
    'Tea': { lat: 43.8419, lon: -96.8359, counties: ['Lincoln'] },
    'Dell Rapids': { lat: 43.8261, lon: -96.7062, counties: ['Minnehaha'] },
    'Hartford': { lat: 43.6230, lon: -96.9428, counties: ['Minnehaha'] },
    'Crooks': { lat: 43.6647, lon: -96.8106, counties: ['Minnehaha'] },
    'Baltic': { lat: 43.7614, lon: -96.7392, counties: ['Minnehaha'] },
    'Colton': { lat: 43.7875, lon: -96.9267, counties: ['Minnehaha'] },
    'Valley Springs': { lat: 43.5833, lon: -96.4653, counties: ['Minnehaha'] },
    'Lennox': { lat: 43.3547, lon: -96.8928, counties: ['Lincoln'] },
    'Canton': { lat: 43.3008, lon: -96.5928, counties: ['Lincoln'] },
    'Worthing': { lat: 43.3297, lon: -96.7678, counties: ['Lincoln'] },
    'Parker': { lat: 43.3975, lon: -97.1367, counties: ['Turner'] },
    'Marion': { lat: 43.4225, lon: -97.2592, counties: ['Turner'] },
    'Freeman': { lat: 43.3525, lon: -97.4392, counties: ['Hutchinson'] },
    'Menno': { lat: 43.2383, lon: -97.5792, counties: ['Hutchinson'] },
    'Scotland': { lat: 43.1497, lon: -97.7167, counties: ['Bon Homme'] },
    'Tyndall': { lat: 42.9942, lon: -97.8628, counties: ['Bon Homme'] },
    'Springfield': { lat: 42.8542, lon: -97.8967, counties: ['Bon Homme'] },
    'Wagner': { lat: 43.0797, lon: -98.2939, counties: ['Charles Mix'] },
    'Lake Andes': { lat: 43.1567, lon: -98.5406, counties: ['Charles Mix'] },
    'Platte': { lat: 43.3867, lon: -98.8439, counties: ['Charles Mix'] },
    'Geddes': { lat: 43.2567, lon: -98.6967, counties: ['Charles Mix'] },
    'Avon': { lat: 43.0017, lon: -98.0594, counties: ['Bon Homme'] },
    'Tripp': { lat: 43.2258, lon: -99.8647, counties: ['Tripp'] },
    'Winner': { lat: 43.3767, lon: -99.8567, counties: ['Tripp'] },
    'Colome': { lat: 43.2583, lon: -99.7147, counties: ['Tripp'] },
    'Gregory': { lat: 43.2325, lon: -99.4306, counties: ['Gregory'] },
    'Burke': { lat: 43.1825, lon: -99.2928, counties: ['Gregory'] },
    'Bonesteel': { lat: 43.0758, lon: -98.9417, counties: ['Gregory'] },
    'Fairfax': { lat: 43.0342, lon: -98.8939, counties: ['Gregory'] },
    'Dallas': { lat: 43.2358, lon: -99.5178, counties: ['Gregory'] },
    'Herrick': { lat: 43.1158, lon: -99.1897, counties: ['Gregory'] },
    'Armour': { lat: 43.3189, lon: -98.3467, counties: ['Douglas'] },
    'Corsica': { lat: 43.4275, lon: -98.4067, counties: ['Douglas'] },
    'Delmont': { lat: 43.2567, lon: -98.1597, counties: ['Douglas'] },
    'Harrison': { lat: 43.4317, lon: -98.5267, counties: ['Douglas'] },
    'Dimock': { lat: 43.4775, lon: -97.9867, counties: ['Hutchinson'] },
    'Kaylor': { lat: 43.1942, lon: -97.8367, counties: ['Hutchinson'] },
    'Milltown': { lat: 43.4258, lon: -97.7939, counties: ['Hutchinson'] },
    'Olivet': { lat: 43.2417, lon: -97.6739, counties: ['Hutchinson'] },
    'Parkston': { lat: 43.3989, lon: -97.9839, counties: ['Hutchinson'] },
    'Bridgewater': { lat: 43.5508, lon: -97.4997, counties: ['McCook'] },
    'Canistota': { lat: 43.6008, lon: -97.2997, counties: ['McCook'] },
    'Montrose': { lat: 43.7008, lon: -97.1839, counties: ['McCook'] },
    'Salem': { lat: 43.7242, lon: -97.3839, counties: ['McCook'] },
    'Spencer': { lat: 43.7275, lon: -97.5997, counties: ['McCook'] },
    'Alpena': { lat: 44.1817, lon: -98.3667, counties: ['Jerauld'] },
    'Wessington Springs': { lat: 44.0792, lon: -98.5697, counties: ['Jerauld'] },
    'Woonsocket': { lat: 44.0539, lon: -98.2767, counties: ['Sanborn'] },
    'Artesian': { lat: 44.0008, lon: -97.9167, counties: ['Sanborn'] },
    'Letcher': { lat: 43.8967, lon: -98.1339, counties: ['Sanborn'] },
    'Howard': { lat: 44.0108, lon: -97.5167, counties: ['Miner'] },
    'Carthage': { lat: 44.1692, lon: -97.7167, counties: ['Miner'] },
    'Fedora': { lat: 44.0089, lon: -97.7839, counties: ['Miner'] },
    'Canova': { lat: 43.8825, lon: -97.5167, counties: ['Miner'] },
    'Ethan': { lat: 43.5458, lon: -98.0008, counties: ['Davison'] },
    'Mount Vernon': { lat: 43.7097, lon: -98.2597, counties: ['Davison'] },
    'Loomis': { lat: 43.7875, lon: -98.1339, counties: ['Hanson'] },
    'Alexandria': { lat: 43.6539, lon: -97.7839, counties: ['Hanson'] },
    'Emery': { lat: 43.6025, lon: -97.6167, counties: ['Hanson'] },
    'Fulton': { lat: 43.7275, lon: -97.8167, counties: ['Hanson'] },
    'Hanson': { lat: 43.6742, lon: -97.7839, counties: ['Hanson'] },
    'Monroe': { lat: 43.4817, lon: -97.2167, counties: ['Turner'] },
    'Centerville': { lat: 43.1175, lon: -96.9617, counties: ['Turner'] },
    'Chancellor': { lat: 43.3725, lon: -96.9839, counties: ['Turner'] },
    'Davis': { lat: 43.2567, lon: -96.9339, counties: ['Turner'] },
    'Hurley': { lat: 43.2758, lon: -97.0997, counties: ['Turner'] },
    'Irene': { lat: 43.0839, lon: -97.2667, counties: ['Turner'] },
    'Viborg': { lat: 43.1739, lon: -97.0839, counties: ['Turner'] },
    'Wakonda': { lat: 43.0089, lon: -97.0997, counties: ['Turner'] },
    'Alcester': { lat: 43.0217, lon: -96.6317, counties: ['Union'] },
    'Beresford': { lat: 43.0817, lon: -96.7839, counties: ['Union'] },
    'Elk Point': { lat: 42.6839, lon: -96.6839, counties: ['Union'] },
    'Jefferson': { lat: 42.6058, lon: -96.5667, counties: ['Union'] },
    'North Sioux City': { lat: 42.5275, lon: -96.4839, counties: ['Union'] },
    'Volin': { lat: 42.9567, lon: -97.1839, counties: ['Yankton'] },
    'Gayville': { lat: 42.8875, lon: -97.5497, counties: ['Yankton'] },
    'Lesterville': { lat: 42.8567, lon: -97.6339, counties: ['Yankton'] },
    'Utica': { lat: 42.9817, lon: -97.7497, counties: ['Yankton'] },
  };

  // Find the closest location to the user
  let closestLocation: string | null = null;
  let closestDistance = Infinity;
  
  for (const [locationName, locationData] of Object.entries(sdLocations)) {
    const distance = calculateDistance(userLat, userLon, locationData.lat, locationData.lon);
    if (distance < closestDistance) {
      closestDistance = distance;
      closestLocation = locationName;
    }
  }
  
  if (!closestLocation) {
    console.log(`❌ Could not determine user's location`);
    return false;
  }
  
  const userCounties = sdLocations[closestLocation].counties;
  console.log(`📍 User appears to be near ${closestLocation} (${closestDistance.toFixed(1)}km away)`);
  console.log(`🏛️ User's counties: ${userCounties.join(', ')}`);
  
  // Check if any of the user's counties are mentioned in the areaDesc
  const areaDescLower = areaDesc.toLowerCase();
  for (const county of userCounties) {
    if (areaDescLower.includes(county.toLowerCase())) {
      console.log(`✅ User's county "${county}" found in alert area`);
      return true;
    }
  }
  
  console.log(`❌ User's counties not found in alert area`);
  return false;
}

function shouldSendNotification(userPrefs: any, alertType: string, currentHour: number): boolean {
  // All alert types are enabled by default, so we only need to check Do Not Disturb settings
  if (!userPrefs) {
    console.log(`No preferences set for user, allowing notification for ${alertType}`);
    return true;
  }
  
  // Check Do Not Disturb settings
  if (userPrefs.doNotDisturb?.enabled) {
    const startHour = userPrefs.doNotDisturb.startHour;
    const endHour = userPrefs.doNotDisturb.endHour;
    if (startHour <= endHour) {
      if (currentHour >= startHour && currentHour <= endHour) {
        console.log(`Notification blocked by Do Not Disturb hours (${startHour}:00-${endHour}:00)`);
        return false;
      }
    } else {
      if (currentHour >= startHour || currentHour <= endHour) {
        console.log(`Notification blocked by Do Not Disturb hours (${startHour}:00-${endHour}:00)`);
        return false;
      }
    }
  }
  
  console.log(`✅ Notification allowed for ${alertType}`);
  return true;
}

async function sendNotificationToUser(userId: string, alertData: any, userPrefs: any) {
  try {
    console.log(`📱 Attempting to send notification to user ${userId} for ${alertData.event}`);
    
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    if (!userDoc.exists) {
      console.log(`❌ User ${userId} not found in database`);
      return;
    }
    const userData = userDoc.data();
    const fcmToken = userData?.fcmToken;
    if (!fcmToken) {
      console.log(`❌ No FCM token for user ${userId}`);
      return;
    }
    
    console.log(`🔑 FCM token found for user ${userId}`);
    
    const currentHour = new Date().getHours();
    console.log(`🕐 Current hour: ${currentHour}`);
    
    if (!shouldSendNotification(userPrefs, alertData.event, currentHour)) {
      console.log(`❌ Notification blocked by preferences for user ${userId}`);
      return;
    }
    
    console.log(`✅ Notification allowed, preparing message...`);
    
    const message = {
      token: fcmToken,
      notification: {
        title: alertData.event,
        body: alertData.headline || alertData.description || 'Weather alert in your area',
      },
      data: {
        alertId: alertData.id,
        alertType: alertData.event,
        areaDesc: alertData.areaDesc,
        severity: alertData.severity,
        urgency: alertData.urgency,
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
      },
      android: {
        priority: 'high' as const,
        notification: {
          channelId: 'weather_alerts',
          priority: 'high' as const,
          defaultSound: true,
          defaultVibrateTimings: true,
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };
    
    console.log(`📤 Sending FCM message to user ${userId}:`, JSON.stringify(message, null, 2));
    
    const response = await admin.messaging().send(message);
    console.log(`✅ Notification sent to user ${userId}: ${response}`);
    
    // Store notification history
    await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('notification_history')
      .add({
        alertId: alertData.id,
        event: alertData.event,
        areaDesc: alertData.areaDesc,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        read: false,
        notifiedDevices: [fcmToken],
        fcmResponse: response,
      });
      
    console.log(`📝 Notification history stored for user ${userId}`);
    
  } catch (error) {
    console.error(`❌ Error sending notification to user ${userId}:`, error);
    console.error(`Error details:`, JSON.stringify(error, Object.getOwnPropertyNames(error)));
  }
}

async function sendNotificationsForAlert(alert: any, db: admin.firestore.Firestore) {
  try {
    console.log(`🚨 Processing alert: ${alert.properties.event}`);
    console.log(`📍 Alert area: ${alert.properties.areaDesc}`);
    console.log(`🆔 Alert ID: ${alert.id}`);
    
    const usersSnapshot = await db.collection('users').get();
    console.log(`🔍 Checking ${usersSnapshot.docs.length} users for alert: ${alert.properties.event}`);
    
    if (usersSnapshot.docs.length === 0) {
      console.log('❌ No users found in database');
      return;
    }
    
    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const userData = userDoc.data();
      console.log(`👤 Processing user: ${userId}`);
      console.log(`   User data:`, JSON.stringify(userData, null, 2));
      
      const userLocation = userData.currentLocation;
      if (!userLocation) {
        console.log(`❌ No location context for user ${userId}`);
        continue;
      }
      
      console.log(`📍 User location: (${userLocation.lat}, ${userLocation.lon})`);
      console.log(`📍 Using location: ${userLocation.isUsingLocation}`);
      if (userLocation.selectedCity) {
        console.log(`📍 Selected city: ${userLocation.selectedCity}`);
      }
      
      // Check if location data is recent (within last 24 hours)
      const locationUpdatedAt = userLocation.updatedAt;
      if (locationUpdatedAt) {
        const updateTime = locationUpdatedAt._seconds ? new Date(locationUpdatedAt._seconds * 1000) : new Date(locationUpdatedAt);
        const hoursSinceUpdate = (Date.now() - updateTime.getTime()) / (1000 * 60 * 60);
        console.log(`🕐 Location last updated: ${hoursSinceUpdate.toFixed(1)} hours ago`);
        
        if (hoursSinceUpdate > 24) {
          console.log(`⚠️ Location data is old (${hoursSinceUpdate.toFixed(1)} hours), may be outdated`);
        }
      }
      
      const prefsDoc = await db.collection('users').doc(userId).collection('preferences').doc('main').get();
      if (!prefsDoc.exists) {
        console.log(`❌ No preferences for user ${userId}`);
        continue;
      }
      
      const userPrefs = prefsDoc.data();
      console.log(`📋 User preferences:`, JSON.stringify(userPrefs, null, 2));
      
      const userLat = userLocation.lat;
      const userLon = userLocation.lon;
      
      console.log(`📍 Checking user ${userId} at (${userLat}, ${userLon}) for alert: ${alert.properties.event}`);
      console.log(`🗺️ Alert geometry:`, JSON.stringify(alert.geometry, null, 2));
      
      if (isLocationInAlertArea(userLat, userLon, alert.geometry, alert.properties.event, alert.properties.areaDesc)) {
        console.log(`✅ User ${userId} is in alert area for ${alert.properties.event}`);
        await sendNotificationToUser(userId, alert.properties, userPrefs);
      } else {
        console.log(`❌ User ${userId} is NOT in alert area for ${alert.properties.event}`);
      }
    }
  } catch (error) {
    console.error('❌ Error sending notifications for alert:', error);
    console.error('Error details:', JSON.stringify(error, Object.getOwnPropertyNames(error)));
  }
}

// Sanitize alert ID for use as Firestore document ID
// Updated to handle NWS alert IDs with forward slashes
function sanitizeAlertId(alertId: string): string {
  // Remove protocol and domain, keep only the unique part
  // Convert forward slashes to underscores
  return alertId
    .replace(/^https?:\/\/[^\/]+\//, '') // Remove protocol and domain
    .replace(/\//g, '_') // Replace remaining slashes with underscores
    .replace(/[^a-zA-Z0-9_-]/g, '_'); // Replace any other invalid chars with underscores
}

export const pollNWSAlerts = functions.pubsub.schedule("every 5 minutes").onRun(async (context: any) => {
  console.log(`🔄 Starting NWS alert polling at ${new Date().toISOString()}`);
  
  // 1. Fetch NWS alerts for South Dakota
  const url = "https://api.weather.gov/alerts/active?area=SD";
  console.log(`📡 Fetching alerts from: ${url}`);
  const response = await fetch(url);
  const data = await response.json();
  console.log(`📊 Received ${data.features ? data.features.length : 0} total alerts from NWS`);

  // 2. Filter for relevant alert types
  const relevantAlerts = data.features.filter(
    (feature: any) =>
      RELEVANT_ALERT_TYPES.includes(feature.properties.event)
  );
  console.log(`🔍 Filtered to ${relevantAlerts.length} relevant alerts:`);
  relevantAlerts.forEach((alert: any) => {
    console.log(`   - ${alert.properties.event} for ${alert.properties.areaDesc} (ID: ${alert.id})`);
  });

  // 3. Compare with Firestore to detect new or updated alerts
  const db = admin.firestore();
  for (const alert of relevantAlerts) {
    const originalAlertId = alert.id; // NWS alert unique ID
    const sanitizedAlertId = sanitizeAlertId(originalAlertId);
    
    console.log(`\n🚨 Processing alert: ${alert.properties.event}`);
    console.log(`   Original ID: ${originalAlertId}`);
    console.log(`   Sanitized ID: ${sanitizedAlertId}`);
    console.log(`   Area: ${alert.properties.areaDesc}`);
    console.log(`   Updated: ${alert.properties.updated}`);
    
    const docRef = db.collection("nws_alerts").doc(sanitizedAlertId);

    // Check if alert already exists and is up to date
    const existingAlertDoc = await db.collection('nws_alerts').doc(sanitizedAlertId).get();
    
    // Use effective time or sent time as fallback if updated is undefined
    const alertUpdateTime = alert.properties.updated || alert.properties.effective || alert.properties.sent;
    const existingUpdateTime = existingAlertDoc.data()?.lastUpdated;
    
    const shouldProcess = !existingAlertDoc.exists || 
                         existingUpdateTime !== alertUpdateTime;
    
    console.log(`   Exists: ${existingAlertDoc.exists}`);
    console.log(`   Alert update time: ${alertUpdateTime}`);
    console.log(`   Existing update time: ${existingUpdateTime}`);
    console.log(`   Should process: ${shouldProcess}`);
    
    if (shouldProcess) {
      // Store/update the alert
      await docRef.set({
        ...alert.properties,
        originalAlertId: originalAlertId, // Store the original ID for reference
        lastUpdated: alertUpdateTime, // Store the update time for future comparisons
        fetchedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`✅ Alert processed: ${sanitizedAlertId} (${alert.properties.event})`);
      // Send notifications for new/updated alerts
      await sendNotificationsForAlert(alert, db);
    } else {
      console.log(`⏭️ Alert already up to date, skipping: ${sanitizedAlertId}`);
    }
  }

  // 4. Clean up alerts older than 7 days
  const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
  const oldAlertsQuery = await db.collection("nws_alerts")
    .where("ends", "<", sevenDaysAgo.toISOString())
    .get();
  console.log(`🧹 Cleaning up ${oldAlertsQuery.docs.length} old alerts`);
  for (const doc of oldAlertsQuery.docs) {
    await doc.ref.delete();
    console.log(`🗑️ Deleted old alert: ${doc.id}`);
  }
  
  console.log(`✅ NWS alert polling completed at ${new Date().toISOString()}`);
  return null;
});

// HTTP endpoint to update user's location context (called from Flutter app)
export const updateUserLocation = functions.https.onRequest(async (req, res) => {
  try {
    const { userId, location } = req.body;
    
    if (!userId || !location) {
      res.status(400).json({ error: 'Missing userId or location data' });
      return;
    }
    
    await admin.firestore().collection('users').doc(userId).set({
      currentLocation: {
        lat: location.lat,
        lon: location.lon,
        isUsingLocation: location.isUsingLocation,
        selectedCity: location.selectedCity,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
    }, { merge: true });
    
    res.json({ success: true });
  } catch (error) {
    console.error('Error updating user location:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// HTTP endpoint to update user's FCM token (called from Flutter app)
export const updateFcmToken = functions.https.onRequest(async (req, res) => {
  try {
    const {userId, fcmToken} = req.body;

    if (!userId || !fcmToken) {
      res.status(400).json({error: "Missing userId or fcmToken"});
      return;
    }

    await admin.firestore().collection("users").doc(userId).set({
      fcmToken: fcmToken,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});

    res.json({success: true});
  } catch (error) {
    console.error('Error updating FCM token:', error);
    try {
      console.error('Error details:', JSON.stringify(error, Object.getOwnPropertyNames(error)));
    } catch (jsonErr) {
      console.error('Error stringification failed:', jsonErr);
    }
    res.status(500).json({error: "Internal server error"});
  }
});

// HTTP endpoint to store notification preferences (called from Flutter app)
export const storeNotificationPreferences = functions.https.onRequest(async (req, res) => {
  try {
    const { userId, preferences } = req.body;
    
    if (!userId || !preferences) {
      res.status(400).json({ error: 'Missing userId or preferences data' });
      return;
    }
    
    await admin.firestore().collection('users').doc(userId).collection('preferences').doc('main').set({
      ...preferences,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    res.json({ success: true });
  } catch (error) {
    console.error('Error storing notification preferences:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// HTTP endpoint to load notification preferences (called from Flutter app)
export const loadNotificationPreferences = functions.https.onRequest(async (req, res) => {
  try {
    const userId = req.query.userId as string;
    
    if (!userId) {
      res.status(400).json({ error: 'Missing userId parameter' });
      return;
    }
    
    const doc = await admin.firestore().collection('users').doc(userId).collection('preferences').doc('main').get();
    
    if (doc.exists) {
      res.json(doc.data());
    } else {
      res.json(null);
    }
  } catch (error) {
    console.error('Error loading notification preferences:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// HTTP endpoint to load notification history (called from Flutter app)
export const loadNotificationHistory = functions.https.onRequest(async (req, res) => {
  try {
    const userId = req.query.userId as string;
    
    if (!userId) {
      res.status(400).json({ error: 'Missing userId parameter' });
      return;
    }
    
    const snapshot = await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('notification_history')
      .orderBy('sentAt', 'desc')
      .limit(50)
      .get();
    
    const history = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
    
    res.json(history);
  } catch (error) {
    console.error('Error loading notification history:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});