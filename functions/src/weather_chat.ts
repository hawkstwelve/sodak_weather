import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import fetch from 'node-fetch';
import { WeatherSummarizer } from './weather_summarizer';
import { PromptBuilder, PromptContext } from './prompt_builder';
import { CacheService } from './cache_service';
import { SmartContextManager } from './context_manager';
import { AIServiceFactory } from './ai_service';
import { ResponseProcessor } from './response_processor';
import { FallbackResponseSystem } from './fallback_responses';

// TODO: Import AI service abstraction, weather summarizer, cache service, etc. when implemented

// Rate limiting configuration
const MAX_REQUESTS_PER_HOUR = 50; // Production rate limit

// Initialize services
let cacheService: any;
let contextManager: any;
let aiService: any;

try {
  cacheService = new CacheService();
  contextManager = new SmartContextManager();
  aiService = AIServiceFactory.createService();
  console.log('✅ Services initialized successfully');
} catch (error) {
  console.error('❌ Error initializing services:', error);
  // Create fallback services
  cacheService = {
    getCachedResponse: async () => null,
    cacheResponse: async () => {},
  };
  contextManager = {
    selectContext: () => '',
    optimizeContextForTokens: (context: string) => context,
    enhanceContextWithHistorical: async (context: string) => context,
  };
  aiService = {
    generateResponse: async () => 'Weather service temporarily unavailable. Please try again later.',
  };
}

// South Dakota city coordinates for location resolution
const SD_CITIES = {
  'Sioux Falls': { lat: 43.5446, lon: -96.7311 },
  'Rapid City': { lat: 44.0805, lon: -103.2310 },
  'Pierre': { lat: 44.3683, lon: -100.3509 },
  'Aberdeen': { lat: 45.4647, lon: -98.4864 },
  'Brookings': { lat: 44.3114, lon: -96.7984 },
  'Current Location': { lat: 43.5446, lon: -96.7311 }, // Default to Sioux Falls
};



// Helper: Rate limiting (per user, per hour)
async function isRateLimited(userId: string): Promise<boolean> {
  const now = Date.now();
  const oneHourAgo = now - 60 * 60 * 1000;
  const ref = admin.firestore().collection('weather_chat_rate_limits').doc(userId);
  const doc = await ref.get();
  let requestTimestamps: number[] = [];
  if (doc.exists) {
    requestTimestamps = doc.data()?.timestamps || [];
    // Remove timestamps older than 1 hour
    requestTimestamps = requestTimestamps.filter(ts => ts > oneHourAgo);
  }
  if (requestTimestamps.length >= MAX_REQUESTS_PER_HOUR) {
    return true;
  }
  // Add current timestamp and update Firestore
  requestTimestamps.push(now);
  await ref.set({ timestamps: requestTimestamps }, { merge: true });
  return false;
}

// Helper: Resolve location to coordinates
function resolveLocation(location: string): { lat: number; lon: number } {
  const locationLower = location.toLowerCase();
  
  // Check for exact city matches
  for (const [cityName, coords] of Object.entries(SD_CITIES)) {
    if (locationLower.includes(cityName.toLowerCase())) {
      return coords;
    }
  }
  
  // Check for partial matches
  if (locationLower.includes('sioux falls') || locationLower.includes('sioux')) {
    return SD_CITIES['Sioux Falls'];
  }
  if (locationLower.includes('rapid city') || locationLower.includes('rapid')) {
    return SD_CITIES['Rapid City'];
  }
  if (locationLower.includes('black hills') || locationLower.includes('black')) {
    return SD_CITIES['Rapid City']; // Black Hills area
  }
  if (locationLower.includes('eastern') || locationLower.includes('east')) {
    return SD_CITIES['Sioux Falls']; // Eastern SD
  }
  if (locationLower.includes('western') || locationLower.includes('west')) {
    return SD_CITIES['Rapid City']; // Western SD
  }
  
  // Default to Sioux Falls
  return SD_CITIES['Sioux Falls'];
}

// Helper: Fetch weather data from Google Weather API
async function fetchGoogleWeatherData(lat: number, lon: number): Promise<any> {
  const googleApiKey = functions.config().google?.weather_api_key;
  if (!googleApiKey) {
    throw new Error('Google Weather API key not configured. Set it with: firebase functions:config:set google.weather_api_key="YOUR_KEY"');
  }

  try {
    // Fetch current conditions
    const currentUrl = `https://weather.googleapis.com/v1/currentConditions:lookup?location.latitude=${lat}&location.longitude=${lon}&unitsSystem=IMPERIAL&key=${googleApiKey}`;
    const currentResponse = await fetch(currentUrl);
    if (!currentResponse.ok) {
      throw new Error(`Failed to fetch current conditions: ${currentResponse.status}`);
    }
    const currentData = await currentResponse.json();

    // Fetch forecast
    const forecastUrl = `https://weather.googleapis.com/v1/forecast/days:lookup?location.latitude=${lat}&location.longitude=${lon}&unitsSystem=IMPERIAL&days=10&pageSize=10&key=${googleApiKey}`;
    const forecastResponse = await fetch(forecastUrl);
    if (!forecastResponse.ok) {
      throw new Error(`Failed to fetch forecast: ${forecastResponse.status}`);
    }
    const forecastData = await forecastResponse.json();

    return {
      currentConditions: currentData,
      forecast: forecastData,
    };
  } catch (error) {
    console.error('Error fetching Google Weather data:', error);
    throw new Error('Failed to fetch weather data from Google Weather API');
  }
}

// Helper: Fetch NWS alerts for location
async function fetchNwsAlerts(lat: number, lon: number): Promise<any[]> {
  try {
    const url = `https://api.weather.gov/alerts/active?point=${lat},${lon}`;
    const response = await fetch(url);
    
    if (!response.ok) {
      console.warn(`Failed to fetch NWS alerts: ${response.status}`);
      return [];
    }
    
    const data = await response.json();
    return data.features || [];
  } catch (error) {
    console.error('Error fetching NWS alerts:', error);
    return [];
  }
}

// Helper: Get weather data for location
async function getWeatherData(location: string): Promise<{ weatherData: any; alerts: any[] }> {
  try {
    // Resolve location to coordinates
    const coords = resolveLocation(location);
    console.log(`📍 Resolved location "${location}" to coordinates: ${coords.lat}, ${coords.lon}`);

    // Fetch weather data from Google Weather API
    const weatherData = await fetchGoogleWeatherData(coords.lat, coords.lon);
    
    // Fetch NWS alerts
    const alerts = await fetchNwsAlerts(coords.lat, coords.lon);
    
    console.log(`🌤️ Fetched weather data for ${location}: ${alerts.length} alerts active`);

    return { weatherData, alerts };
  } catch (error) {
    console.error('Error fetching weather data:', error);
    throw new Error('Failed to fetch weather data');
  }
}

// Helper: Get conversation history
async function getConversationHistory(userId: string, limit: number = 5): Promise<string[]> {
  try {
    const ref = admin.firestore().collection('weather_chat_history').doc(userId);
    const doc = await ref.get();
    
    if (!doc.exists) {
      return [];
    }
    
    const data = doc.data();
    const history = data?.messages || [];
    
    // Return last N exchanges (each exchange is 2 messages: user + assistant)
    return history.slice(-limit * 2);
  } catch (error) {
    console.error('Error fetching conversation history:', error);
    return [];
  }
}

// Helper: Save conversation history
async function saveConversationHistory(userId: string, userMessage: string, assistantMessage: string): Promise<void> {
  try {
    const ref = admin.firestore().collection('weather_chat_history').doc(userId);
    const timestamp = Date.now();
    
    await ref.set({
      messages: admin.firestore.FieldValue.arrayUnion(
        `User: ${userMessage}`,
        `Assistant: ${assistantMessage}`
      ),
      lastUpdated: timestamp,
    }, { merge: true });
  } catch (error) {
    console.error('Error saving conversation history:', error);
    // Don't throw error as history saving is not critical
  }
}

// Main weather chat function
export const weatherChat = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
  // Allow unauthenticated calls for weather chat
  const userId = context.auth?.uid || 'anonymous';
  const { question, location } = data;

  console.log(`🌤️ Weather chat request from user ${userId} at ${location}`);





  // Check rate limiting BEFORE processing the request
  if (await isRateLimited(userId)) {
    throw new functions.https.HttpsError('resource-exhausted', 'Rate limit exceeded. Please try again later.');
  }

  try {
    // Check cache for similar questions
    const cachedResponse = await cacheService.getCachedResponse(question, location, userId);
    if (cachedResponse) {
      console.log(`✅ Returning cached response for user ${userId}`);
      return {
        result: cachedResponse.response,
        cached: true,
        weatherContext: cachedResponse.weatherContext,
      };
    }

    // Get weather data and alerts
    const { weatherData, alerts } = await getWeatherData(location);
    
    // Summarize weather data
    const weatherSummary = await WeatherSummarizer.summarizeWeatherData(location, weatherData, alerts);
    
    // Apply smart context selection
    const selectedContext = contextManager.selectContext(question, weatherSummary);
    
    // Extract question context for processing
    const questionContext = PromptBuilder.extractQuestionContext(question);
    
    // Optimize context for token efficiency
    const optimizedContext = contextManager.optimizeContextForTokens(selectedContext, 2000);
    
    // Enhance with historical context if needed
    let finalContext = optimizedContext;
    if (questionContext.southDakotaContext === 'agricultural' || questionContext.weatherType === 'alerts') {
      finalContext = await contextManager.enhanceContextWithHistorical(optimizedContext, location);
    }

    // Get conversation history
    const conversationHistory = await getConversationHistory(userId);

    // Build prompt context
    const promptContext: PromptContext = {
      question,
      location,
      timestamp: new Date().toISOString(),
      userId,
      weatherSummary: finalContext,
      conversationHistory,
      userPreferences: {
        units: 'imperial',
        language: 'English',
      },
    };

    // Build optimized prompt
    const prompt = await PromptBuilder.buildPrompt(promptContext);

    // Log context summary for monitoring
    console.log(`📊 Context summary: ${finalContext.next_3_days?.length || 0} forecast days available`);

    // Generate AI response
    let aiResponse: string;
    try {
      aiResponse = await aiService.generateResponse(prompt);
    } catch (aiError) {
      console.error('AI service error:', aiError);
      // Use fallback response
      const fallbackScenario = FallbackResponseSystem.determineFallbackScenario(aiError, true);
      const fallbackResult = FallbackResponseSystem.getFallbackResponse(fallbackScenario, finalContext, question);
      aiResponse = fallbackResult.response;
    }

    // Process and enhance the response
    const responseProcessor = new ResponseProcessor(finalContext, questionContext);
    const processedResponse = await responseProcessor.processResponse(aiResponse);
    const finalResponse = processedResponse.processedResponse;

    // Cache the response
    await cacheService.cacheResponse(question, location, finalResponse, finalContext, userId);

    // Save conversation history
    await saveConversationHistory(userId, question, finalResponse);

    console.log(`✅ Successfully processed weather chat request for user ${userId}`);

    return {
      result: finalResponse,
      cached: false,
      weatherContext: finalContext,
      questionAnalysis: questionContext,
      processedResponse: {
        actionableRecommendations: processedResponse.actionableRecommendations,
        weatherDataReferences: processedResponse.weatherDataReferences,
        followUpQuestions: processedResponse.followUpQuestions,
        responseType: processedResponse.responseType,
        confidence: processedResponse.confidence,
      },
    };

  } catch (error) {
    console.error('Error in weather chat function:', error);
    console.error('Error details:', {
      message: error instanceof Error ? error.message : 'Unknown error',
      stack: error instanceof Error ? error.stack : 'No stack trace',
      code: (error as any)?.code || 'No error code',
    });
    
    // Return fallback response for any errors
    const fallbackScenario = FallbackResponseSystem.determineFallbackScenario(error, false);
    const fallbackResult = FallbackResponseSystem.getFallbackResponse(fallbackScenario);
    const fallbackResponse = fallbackResult.response;
    
    return {
      result: fallbackResponse,
      error: 'Weather service temporarily unavailable',
      cached: false,
    };
  }
}); 