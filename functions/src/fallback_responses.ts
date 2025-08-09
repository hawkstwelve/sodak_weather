import { WeatherSummary } from './weather_summarizer';

// Fallback scenario types
export type FallbackScenario = 
  | 'no_weather_data'
  | 'ai_service_unavailable'
  | 'invalid_response'
  | 'rate_limit_exceeded'
  | 'network_error'
  | 'general_error'
  | 'temperature_question'
  | 'precipitation_question'
  | 'wind_question'
  | 'alerts_question'
  | 'planning_question';

// Fallback response interface
export interface FallbackResponse {
  response: string;
  confidence: number;
  scenario: FallbackScenario;
  includesWeatherData: boolean;
}

export class FallbackResponseSystem {
  private static readonly FALLBACK_RESPONSES: Record<FallbackScenario, string[]> = {
    no_weather_data: [
      "I'm currently unable to access current weather data for your location. Please check your local weather service for the most up-to-date information.",
      "Weather data is temporarily unavailable. For accurate current conditions, I recommend checking the National Weather Service website.",
      "I don't have access to current weather information right now. Please consult your local weather station for real-time updates.",
    ],
    
    ai_service_unavailable: [
      "I'm experiencing technical difficulties with my weather analysis service. Please try again in a few minutes.",
      "My weather processing service is temporarily unavailable. For immediate weather information, please check your local weather service.",
      "I'm having trouble processing your weather question right now. Please try again later or check a weather website.",
    ],
    
    invalid_response: [
      "I received an unclear response from my weather service. For accurate information, please check your local weather forecast.",
      "The weather data I received seems incomplete. I recommend checking the National Weather Service for reliable information.",
      "I'm not confident in the weather information I received. Please verify with your local weather service.",
    ],
    
    rate_limit_exceeded: [
      "I've reached my limit for weather requests. Please try again in about an hour, or check your local weather service for immediate information.",
      "I'm processing too many weather requests right now. Please wait a bit before asking another question, or check a weather website.",
      "I need to take a short break from processing weather questions. Please try again later or check your local weather forecast.",
    ],
    
    network_error: [
      "I'm having trouble connecting to weather services. Please check your internet connection and try again.",
      "Network issues are preventing me from accessing weather data. Please try again when your connection is stable.",
      "I can't reach the weather services right now. Please check your connection and try again, or use a weather website.",
    ],
    
    general_error: [
      "I encountered an unexpected error while processing your weather question. Please try again or check your local weather service.",
      "Something went wrong while I was getting weather information. Please try again, or check the National Weather Service website.",
      "I'm having technical difficulties. Please try again in a moment, or check your local weather forecast for immediate information.",
    ],
    
    temperature_question: [
      "I can't access current temperature data right now. Please check your local weather service for accurate temperature information.",
      "Temperature data is currently unavailable. For real-time temperature readings, I recommend checking your local weather station.",
      "I'm unable to provide temperature information at the moment. Please check a weather website for current temperature data.",
    ],
    
    precipitation_question: [
      "I can't access precipitation data right now. Please check your local weather service for rain and snow information.",
      "Precipitation data is temporarily unavailable. For accurate rain and snow forecasts, check the National Weather Service.",
      "I'm unable to provide precipitation information. Please check your local weather forecast for rain and snow details.",
    ],
    
    wind_question: [
      "I can't access wind data right now. Please check your local weather service for current wind conditions.",
      "Wind information is temporarily unavailable. For accurate wind speeds and directions, check your local weather station.",
      "I'm unable to provide wind information. Please check a weather website for current wind conditions.",
    ],
    
    alerts_question: [
      "I can't access weather alert information right now. Please check the National Weather Service for any active alerts in your area.",
      "Weather alert data is temporarily unavailable. For important weather warnings, please check your local weather service.",
      "I'm unable to provide alert information. Please check the National Weather Service website for any active weather alerts.",
    ],
    
    planning_question: [
      "I can't access weather forecast data right now. For planning purposes, please check your local weather service for upcoming conditions.",
      "Forecast data is temporarily unavailable. For planning outdoor activities, I recommend checking the National Weather Service.",
      "I'm unable to provide planning weather information. Please check your local weather forecast for upcoming conditions.",
    ],
  };

  /**
   * Get a fallback response for a specific scenario
   */
  static getFallbackResponse(
    scenario: FallbackScenario,
    weatherContext?: WeatherSummary,
    originalQuestion?: string
  ): FallbackResponse {
    const responses = this.FALLBACK_RESPONSES[scenario];
    const randomResponse = responses[Math.floor(Math.random() * responses.length)];
    
    // If we have weather context, try to enhance the response
    let enhancedResponse = randomResponse;
    let confidence = 0.8;
    let includesWeatherData = false;
    
    if (weatherContext) {
      const enhanced = this.enhanceResponseWithWeatherData(
        randomResponse,
        weatherContext,
        originalQuestion
      );
      enhancedResponse = enhanced.response;
      confidence = enhanced.confidence;
      includesWeatherData = enhanced.includesWeatherData;
    }
    
    return {
      response: enhancedResponse,
      confidence,
      scenario,
      includesWeatherData,
    };
  }

  /**
   * Enhance fallback response with available weather data
   */
  private static enhanceResponseWithWeatherData(
    baseResponse: string,
    weatherContext: WeatherSummary,
    originalQuestion?: string
  ): { response: string; confidence: number; includesWeatherData: boolean } {
    try {
      const currentTemp = weatherContext.today.high_temp;
      const condition = weatherContext.today.condition;
      const alerts = weatherContext.alerts;
      
      // If we have basic weather data, enhance the response
      if (currentTemp !== undefined && condition) {
        const weatherInfo = `Currently, it's ${currentTemp}°F with ${condition.toLowerCase()}`;
        
        // Add alert information if available
        let alertInfo = '';
        if (alerts && alerts.length > 0) {
          alertInfo = `. There are ${alerts.length} active weather alert${alerts.length > 1 ? 's' : ''} in your area`;
        }
        
        const enhancedResponse = `${weatherInfo}${alertInfo}. ${baseResponse}`;
        
        return {
          response: enhancedResponse,
          confidence: 0.9,
          includesWeatherData: true,
        };
      }
      
      return {
        response: baseResponse,
        confidence: 0.8,
        includesWeatherData: false,
      };
      
    } catch (error) {
      console.error('Error enhancing fallback response:', error);
      return {
        response: baseResponse,
        confidence: 0.8,
        includesWeatherData: false,
      };
    }
  }

  /**
   * Determine the appropriate fallback scenario based on error type
   */
  static determineFallbackScenario(error: any, hasWeatherData: boolean = false): FallbackScenario {
    if (error instanceof Error) {
      const errorMessage = error.message.toLowerCase();
      
      if (errorMessage.includes('rate limit') || errorMessage.includes('resource-exhausted')) {
        return 'rate_limit_exceeded';
      }
      
      if (errorMessage.includes('network') || errorMessage.includes('connection')) {
        return 'network_error';
      }
      
      if (errorMessage.includes('invalid') || errorMessage.includes('malformed')) {
        return 'invalid_response';
      }
      
      if (errorMessage.includes('unavailable') || errorMessage.includes('service')) {
        return 'ai_service_unavailable';
      }
    }
    
    if (!hasWeatherData) {
      return 'no_weather_data';
    }
    
    return 'general_error';
  }

  /**
   * Get context-aware fallback based on question type
   */
  static getContextAwareFallback(
    originalQuestion: string,
    weatherContext?: WeatherSummary
  ): FallbackResponse {
    const question = originalQuestion.toLowerCase();
    
    // Determine question type
    let scenario: FallbackScenario = 'general_error';
    
    if (question.includes('temperature') || question.includes('hot') || question.includes('cold')) {
      scenario = 'temperature_question';
    } else if (question.includes('rain') || question.includes('snow') || question.includes('precipitation')) {
      scenario = 'precipitation_question';
    } else if (question.includes('wind') || question.includes('breezy')) {
      scenario = 'wind_question';
    } else if (question.includes('alert') || question.includes('warning')) {
      scenario = 'alerts_question';
    } else if (question.includes('plan') || question.includes('weekend') || question.includes('outdoor')) {
      scenario = 'planning_question';
    }
    
    return this.getFallbackResponse(scenario, weatherContext, originalQuestion);
  }

  /**
   * Create a personalized fallback response
   */
  static createPersonalizedFallback(
    weatherContext: WeatherSummary,
    originalQuestion: string,
    userLocation: string
  ): FallbackResponse {
    try {
      const currentTemp = weatherContext.today.high_temp;
      const condition = weatherContext.today.condition;
      const forecast = weatherContext.next_3_days;
      const alerts = weatherContext.alerts;
      
      let response = `I can see that in ${userLocation}, it's currently ${currentTemp}°F with ${condition.toLowerCase()}. `;
      
      // Add forecast information if available
      if (forecast && forecast.length > 0) {
        const tomorrow = forecast[0];
        response += `Tomorrow looks like ${tomorrow.condition.toLowerCase()} with a high of ${tomorrow.high_temp}°F. `;
      }
      
      // Add alert information if available
      if (alerts && alerts.length > 0) {
        response += `There ${alerts.length === 1 ? 'is' : 'are'} ${alerts.length} active weather alert${alerts.length > 1 ? 's' : ''} in your area. `;
      }
      
      response += "For the most detailed and up-to-date information, I recommend checking your local weather service.";
      
      return {
        response,
        confidence: 0.95,
        scenario: 'no_weather_data',
        includesWeatherData: true,
      };
      
    } catch (error) {
      console.error('Error creating personalized fallback:', error);
      return this.getFallbackResponse('general_error', weatherContext, originalQuestion);
    }
  }

  /**
   * Get all available fallback scenarios
   */
  static getAvailableScenarios(): FallbackScenario[] {
    return Object.keys(this.FALLBACK_RESPONSES) as FallbackScenario[];
  }

  /**
   * Get fallback response statistics
   */
  static getFallbackStats(): {
    totalScenarios: number;
    totalResponses: number;
    scenarios: Record<FallbackScenario, number>;
  } {
    const scenarios = this.getAvailableScenarios();
    const scenarioCounts: Record<FallbackScenario, number> = {} as Record<FallbackScenario, number>;
    let totalResponses = 0;
    
    scenarios.forEach(scenario => {
      const responseCount = this.FALLBACK_RESPONSES[scenario].length;
      scenarioCounts[scenario] = responseCount;
      totalResponses += responseCount;
    });
    
    return {
      totalScenarios: scenarios.length,
      totalResponses,
      scenarios: scenarioCounts,
    };
  }

  /**
   * Validate fallback response quality
   */
  static validateFallbackResponse(response: string): {
    isValid: boolean;
    issues: string[];
  } {
    const issues: string[] = [];
    
    // Check for minimum length
    if (response.length < 20) {
      issues.push('Response too short');
    }
    
    // Check for maximum length
    if (response.length > 500) {
      issues.push('Response too long');
    }
    
    // Check for proper sentence structure
    if (!response.endsWith('.') && !response.endsWith('!') && !response.endsWith('?')) {
      issues.push('Missing sentence ending');
    }
    
    // Check for weather-related keywords
    const weatherKeywords = ['weather', 'temperature', 'forecast', 'conditions', 'service'];
    const hasWeatherKeywords = weatherKeywords.some(keyword => 
      response.toLowerCase().includes(keyword)
    );
    
    if (!hasWeatherKeywords) {
      issues.push('Missing weather-related content');
    }
    
    return {
      isValid: issues.length === 0,
      issues,
    };
  }
} 