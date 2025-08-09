import { WeatherSummary } from './weather_summarizer';

// Validation result interface
export interface ValidationResult {
  isValid: boolean;
  sanitizedResponse: string;
  warnings: string[];
  confidence: number; // 0-1 scale
}

// Validation rules interface
export interface ValidationRules {
  maxTemperature: number;
  minTemperature: number;
  maxWindSpeed: number;
  maxPrecipitationChance: number;
  maxResponseLength: number;
  minResponseLength: number;
}

export class ResponseValidator {
  private static readonly DEFAULT_RULES: ValidationRules = {
    maxTemperature: 130, // Fahrenheit
    minTemperature: -50, // Fahrenheit
    maxWindSpeed: 200, // mph
    maxPrecipitationChance: 100, // percentage
    maxResponseLength: 1000, // characters
    minResponseLength: 10, // characters
  };

  private weatherContext: WeatherSummary;
  private rules: ValidationRules;

  constructor(weatherContext: WeatherSummary, rules?: Partial<ValidationRules>) {
    this.weatherContext = weatherContext;
    this.rules = { ...ResponseValidator.DEFAULT_RULES, ...rules };
  }

  /**
   * Main validation method - validates AI response against weather data
   */
  validateResponse(aiResponse: string): ValidationResult {
    try {
  

      const warnings: string[] = [];
      let confidence = 1.0;
      let sanitizedResponse = aiResponse.trim();

      // Basic response validation
      const basicValidation = this.validateBasicResponse(sanitizedResponse);
      warnings.push(...basicValidation.warnings);
      confidence *= basicValidation.confidence;

      // Weather data validation
      const weatherValidation = this.validateWeatherData(sanitizedResponse);
      warnings.push(...weatherValidation.warnings);
      confidence *= weatherValidation.confidence;

      // Content filtering
      const contentValidation = this.filterNonWeatherContent(sanitizedResponse);
      sanitizedResponse = contentValidation.sanitizedResponse;
      warnings.push(...contentValidation.warnings);
      confidence *= contentValidation.confidence;

      // Temperature consistency check
      const tempValidation = this.validateTemperatureConsistency(sanitizedResponse);
      warnings.push(...tempValidation.warnings);
      confidence *= tempValidation.confidence;

      // Final response formatting
      sanitizedResponse = this.formatResponse(sanitizedResponse);

      const result: ValidationResult = {
        isValid: confidence > 0.5 && sanitizedResponse.length >= this.rules.minResponseLength,
        sanitizedResponse,
        warnings,
        confidence,
      };

      console.log(`✅ Validation complete - Confidence: ${(confidence * 100).toFixed(1)}%, Valid: ${result.isValid}`);
      
      return result;

    } catch (error) {
      console.error('Error during response validation:', error);
      return {
        isValid: false,
        sanitizedResponse: 'I apologize, but I encountered an error while processing the weather information. Please try again.',
        warnings: [`Validation error: ${error}`],
        confidence: 0,
      };
    }
  }

  /**
   * Validates basic response properties
   */
  private validateBasicResponse(response: string): { warnings: string[]; confidence: number } {
    const warnings: string[] = [];
    let confidence = 1.0;

    // Check response length
    if (response.length > this.rules.maxResponseLength) {
      warnings.push(`Response too long (${response.length} chars, max ${this.rules.maxResponseLength})`);
      confidence *= 0.8;
    }

    if (response.length < this.rules.minResponseLength) {
      warnings.push(`Response too short (${response.length} chars, min ${this.rules.minResponseLength})`);
      confidence *= 0.7;
    }

    // Check for empty or null response
    if (!response || response.trim().length === 0) {
      warnings.push('Empty response detected');
      confidence *= 0.1;
    }

    // Check for common error patterns
    const errorPatterns = [
      /i'm sorry/i,
      /i cannot/i,
      /i don't have access/i,
      /i'm unable to/i,
      /i don't know/i,
      /no information available/i,
    ];

    for (const pattern of errorPatterns) {
      if (pattern.test(response)) {
        warnings.push('Response contains error pattern');
        confidence *= 0.6;
        break;
      }
    }

    return { warnings, confidence };
  }

  /**
   * Validates weather data consistency
   */
  private validateWeatherData(response: string): { warnings: string[]; confidence: number } {
    const warnings: string[] = [];
    let confidence = 1.0;

    // Extract temperature values from response
    const tempMatches = response.match(/(-?\d+)\s*°?[FC]/gi);
    if (tempMatches) {
      for (const match of tempMatches) {
        const temp = parseInt(match.replace(/[°FC]/gi, ''));
        
        // Check if it's Fahrenheit (assume F for US weather)
        if (temp > this.rules.maxTemperature) {
          warnings.push(`Temperature too high: ${temp}°F`);
          confidence *= 0.7;
        }
        
        if (temp < this.rules.minTemperature) {
          warnings.push(`Temperature too low: ${temp}°F`);
          confidence *= 0.7;
        }
      }
    }

    // Extract wind speed values
    const windMatches = response.match(/(\d+)\s*(?:mph|miles per hour)/gi);
    if (windMatches) {
      for (const match of windMatches) {
        const windSpeed = parseInt(match.replace(/\s*(?:mph|miles per hour)/gi, ''));
        
        if (windSpeed > this.rules.maxWindSpeed) {
          warnings.push(`Wind speed too high: ${windSpeed} mph`);
          confidence *= 0.8;
        }
      }
    }

    // Extract precipitation chances
    const precipMatches = response.match(/(\d+)%\s*(?:chance|probability)/gi);
    if (precipMatches) {
      for (const match of precipMatches) {
        const chance = parseInt(match.replace(/%\s*(?:chance|probability)/gi, ''));
        
        if (chance > this.rules.maxPrecipitationChance) {
          warnings.push(`Precipitation chance too high: ${chance}%`);
          confidence *= 0.8;
        }
      }
    }

    return { warnings, confidence };
  }

  /**
   * Filters out non-weather content
   */
  private filterNonWeatherContent(response: string): { sanitizedResponse: string; warnings: string[]; confidence: number } {
    const warnings: string[] = [];
    let confidence = 1.0;
    let sanitized = response;

    // Remove non-weather related content
    const nonWeatherPatterns = [
      /i am an ai language model/i,
      /i am a language model/i,
      /i cannot provide/i,
      /i don't have real-time/i,
      /i don't have access to current/i,
      /please check a weather service/i,
      /i recommend checking/i,
    ];

    for (const pattern of nonWeatherPatterns) {
      if (pattern.test(sanitized)) {
        sanitized = sanitized.replace(pattern, '');
        warnings.push('Removed non-weather content');
        confidence *= 0.8;
      }
    }

    // Remove excessive apologies or disclaimers
    const apologyPatterns = [
      /i apologize,? but/i,
      /i'm sorry,? but/i,
      /unfortunately,? i/i,
      /i regret to inform/i,
    ];

    for (const pattern of apologyPatterns) {
      if (pattern.test(sanitized)) {
        sanitized = sanitized.replace(pattern, '');
        warnings.push('Removed excessive apologies');
        confidence *= 0.9;
      }
    }

    // Clean up extra whitespace
    sanitized = sanitized.replace(/\s+/g, ' ').trim();

    return { sanitizedResponse: sanitized, warnings, confidence };
  }

  /**
   * Validates temperature consistency with weather context
   */
  private validateTemperatureConsistency(response: string): { warnings: string[]; confidence: number } {
    const warnings: string[] = [];
    let confidence = 1.0;

    // Extract current temperature from weather context
    const currentTemp = this.weatherContext.today.high_temp;
    
    // Extract temperature from response
    const tempMatches = response.match(/(-?\d+)\s*°?[FC]/gi);
    if (tempMatches && currentTemp !== undefined) {
      for (const match of tempMatches) {
        const responseTemp = parseInt(match.replace(/[°FC]/gi, ''));
        
        // Check if temperature is within reasonable range of current conditions
        const tempDiff = Math.abs(responseTemp - currentTemp);
        if (tempDiff > 30) { // More than 30°F difference
          warnings.push(`Temperature inconsistency: response ${responseTemp}°F vs current ${currentTemp}°F`);
          confidence *= 0.6;
        }
      }
    }

    return { warnings, confidence };
  }

  /**
   * Formats the final response
   */
  private formatResponse(response: string): string {
    let formatted = response;

    // Ensure proper sentence structure
    if (!formatted.endsWith('.') && !formatted.endsWith('!') && !formatted.endsWith('?')) {
      formatted += '.';
    }

    // Capitalize first letter
    if (formatted.length > 0) {
      formatted = formatted.charAt(0).toUpperCase() + formatted.slice(1);
    }

    // Remove multiple periods
    formatted = formatted.replace(/\.+/g, '.');

    return formatted;
  }

  /**
   * Creates a fallback response when validation fails
   */
  static createFallbackResponse(weatherContext: WeatherSummary, originalQuestion: string): string {
    const currentTemp = weatherContext.today.high_temp;
    const condition = weatherContext.today.condition;
    
    return `Based on current conditions in your area, it's ${currentTemp}°F with ${condition.toLowerCase()}. For the most accurate and up-to-date weather information, I recommend checking your local weather service.`;
  }

  /**
   * Quick validation check for response quality
   */
  static quickValidate(response: string): boolean {
    if (!response || response.trim().length < 10) return false;
    
    // Check for common error patterns
    const errorPatterns = [
      /i'm sorry/i,
      /i cannot/i,
      /i don't have access/i,
      /i'm unable to/i,
    ];
    
    return !errorPatterns.some(pattern => pattern.test(response));
  }

  /**
   * Get validation statistics
   */
  getValidationStats(): {
    rules: ValidationRules;
    weatherContextAvailable: boolean;
    currentTemperature: number | undefined;
  } {
    return {
      rules: { ...this.rules },
      weatherContextAvailable: !!this.weatherContext,
      currentTemperature: this.weatherContext.today.high_temp,
    };
  }
}
 