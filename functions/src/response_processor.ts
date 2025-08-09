import { WeatherSummary } from './weather_summarizer';
import { ResponseValidator, ValidationResult } from './response_validator';

// Processed response interface
export interface ProcessedResponse {
  originalResponse: string;
  processedResponse: string;
  actionableRecommendations: string[];
  weatherDataReferences: WeatherDataReference[];
  followUpQuestions: string[];
  validationResult: ValidationResult;
  confidence: number;
  responseType: 'current' | 'forecast' | 'alert' | 'planning' | 'comparison';
}

// Weather data reference interface
export interface WeatherDataReference {
  type: 'temperature' | 'precipitation' | 'wind' | 'condition' | 'alert';
  value: string;
  unit?: string;
  context: string;
  confidence: number;
}

// Actionable recommendation interface
export interface ActionableRecommendation {
  action: string;
  urgency: 'low' | 'medium' | 'high';
  category: 'safety' | 'planning' | 'preparation' | 'activity';
  reasoning: string;
}

export class ResponseProcessor {
  private weatherContext: WeatherSummary;
  private questionContext: any;
  private responseValidator: ResponseValidator;

  constructor(weatherContext: WeatherSummary, questionContext: any) {
    this.weatherContext = weatherContext;
    this.questionContext = questionContext;
    this.responseValidator = new ResponseValidator(weatherContext);
  }

  /**
   * Main processing method - enhances AI response with structured data
   */
  async processResponse(aiResponse: string): Promise<ProcessedResponse> {
    try {
      console.log(`🔄 Processing AI response (${aiResponse.length} characters)`);

      // Validate the response first
      const validationResult = this.responseValidator.validateResponse(aiResponse);
      
      if (!validationResult.isValid) {
        console.warn(`⚠️ Response validation failed: ${validationResult.warnings.join(', ')}`);
      }

      // Extract actionable recommendations
      const actionableRecommendations = this.extractActionableRecommendations(validationResult.sanitizedResponse);

      // Extract and format weather data references
      const weatherDataReferences = this.extractWeatherDataReferences(validationResult.sanitizedResponse);

      // Generate follow-up questions
      const followUpQuestions = this.generateFollowUpQuestions(validationResult.sanitizedResponse);

      // Determine response type
      const responseType = this.determineResponseType(validationResult.sanitizedResponse);

      // Enhance the response with structured formatting
      const processedResponse = this.enhanceResponseFormat(validationResult.sanitizedResponse, actionableRecommendations);

      const result: ProcessedResponse = {
        originalResponse: aiResponse,
        processedResponse,
        actionableRecommendations: actionableRecommendations.map(rec => rec.action),
        weatherDataReferences: weatherDataReferences,
        followUpQuestions,
        validationResult,
        confidence: validationResult.confidence,
        responseType,
      };

      console.log(`✅ Response processing complete - Type: ${responseType}, Confidence: ${(validationResult.confidence * 100).toFixed(1)}%`);
      
      return result;

    } catch (error) {
      console.error('Error during response processing:', error);
      return this.createFallbackProcessedResponse(aiResponse, error);
    }
  }

  /**
   * Extracts actionable recommendations from the response
   */
  private extractActionableRecommendations(response: string): ActionableRecommendation[] {
    const recommendations: ActionableRecommendation[] = [];
    const responseLower = response.toLowerCase();

    // Safety recommendations
    if (responseLower.includes('warning') || responseLower.includes('alert') || responseLower.includes('severe')) {
      recommendations.push({
        action: 'Monitor weather alerts and take safety precautions',
        urgency: 'high',
        category: 'safety',
        reasoning: 'Severe weather conditions detected',
      });
    }

    if (responseLower.includes('flood') || responseLower.includes('flash flood')) {
      recommendations.push({
        action: 'Avoid low-lying areas and monitor flood warnings',
        urgency: 'high',
        category: 'safety',
        reasoning: 'Flood risk identified',
      });
    }

    if (responseLower.includes('tornado') || responseLower.includes('severe storm')) {
      recommendations.push({
        action: 'Seek shelter immediately and monitor tornado warnings',
        urgency: 'high',
        category: 'safety',
        reasoning: 'Tornado or severe storm threat',
      });
    }

    // Planning recommendations
    if (responseLower.includes('plan') || responseLower.includes('schedule') || responseLower.includes('reschedule')) {
      recommendations.push({
        action: 'Consider rescheduling outdoor activities',
        urgency: 'medium',
        category: 'planning',
        reasoning: 'Weather conditions may impact plans',
      });
    }

    if (responseLower.includes('good for') || responseLower.includes('favorable')) {
      recommendations.push({
        action: 'Weather conditions are favorable for outdoor activities',
        urgency: 'low',
        category: 'activity',
        reasoning: 'Positive weather conditions identified',
      });
    }

    // Preparation recommendations
    if (responseLower.includes('cold') || responseLower.includes('freeze') || responseLower.includes('frost')) {
      recommendations.push({
        action: 'Prepare for cold weather and protect sensitive plants',
        urgency: 'medium',
        category: 'preparation',
        reasoning: 'Cold weather conditions expected',
      });
    }

    if (responseLower.includes('hot') || responseLower.includes('heat')) {
      recommendations.push({
        action: 'Stay hydrated and avoid prolonged outdoor exposure',
        urgency: 'medium',
        category: 'preparation',
        reasoning: 'Hot weather conditions expected',
      });
    }

    // Agricultural recommendations
    if (this.questionContext.southDakotaContext === 'agricultural') {
      if (responseLower.includes('harvest') || responseLower.includes('plant')) {
        recommendations.push({
          action: 'Consider weather impact on agricultural operations',
          urgency: 'medium',
          category: 'planning',
          reasoning: 'Agricultural weather considerations',
        });
      }
    }

    return recommendations;
  }

  /**
   * Extracts and formats weather data references
   */
  private extractWeatherDataReferences(response: string): WeatherDataReference[] {
    const references: WeatherDataReference[] = [];

    // Extract temperature references
    const tempMatches = response.match(/(-?\d+)\s*°?[FC]/gi);
    if (tempMatches) {
      tempMatches.forEach(match => {
        const temp = parseInt(match.replace(/[°FC]/gi, ''));
        references.push({
          type: 'temperature',
          value: temp.toString(),
          unit: '°F',
          context: 'temperature reading',
          confidence: 0.9,
        });
      });
    }

    // Extract precipitation references
    const precipMatches = response.match(/(\d+)%\s*(?:chance|probability)/gi);
    if (precipMatches) {
      precipMatches.forEach(match => {
        const chance = match.replace(/%\s*(?:chance|probability)/gi, '');
        references.push({
          type: 'precipitation',
          value: chance,
          unit: '%',
          context: 'precipitation probability',
          confidence: 0.8,
        });
      });
    }

    // Extract wind references
    const windMatches = response.match(/(\d+)\s*(?:mph|miles per hour)/gi);
    if (windMatches) {
      windMatches.forEach(match => {
        const speed = match.replace(/\s*(?:mph|miles per hour)/gi, '');
        references.push({
          type: 'wind',
          value: speed,
          unit: 'mph',
          context: 'wind speed',
          confidence: 0.8,
        });
      });
    }

    // Extract weather conditions
    const conditionKeywords = ['sunny', 'cloudy', 'rainy', 'snowy', 'stormy', 'clear', 'partly cloudy'];
    conditionKeywords.forEach(condition => {
      if (response.toLowerCase().includes(condition)) {
        references.push({
          type: 'condition',
          value: condition,
          context: 'weather condition',
          confidence: 0.7,
        });
      }
    });

    // Extract alerts
    if (response.toLowerCase().includes('alert') || response.toLowerCase().includes('warning')) {
      references.push({
        type: 'alert',
        value: 'weather alert',
        context: 'active weather alert',
        confidence: 0.6,
      });
    }

    return references;
  }

  /**
   * Generates relevant follow-up questions
   */
  private generateFollowUpQuestions(response: string): string[] {
    const questions: string[] = [];
    const responseLower = response.toLowerCase();

    // Temperature-related follow-ups
    if (responseLower.includes('temperature') || responseLower.includes('hot') || responseLower.includes('cold')) {
      if (this.questionContext.timeFrame === 'current') {
        questions.push('What will the temperature be like tomorrow?');
        questions.push('How does this compare to normal temperatures for this time of year?');
      } else if (this.questionContext.timeFrame === 'today') {
        questions.push('What about the temperature for the rest of the week?');
      }
    }

    // Precipitation-related follow-ups
    if (responseLower.includes('rain') || responseLower.includes('snow') || responseLower.includes('precipitation')) {
      questions.push('When is the best time to plan outdoor activities?');
      if (this.questionContext.southDakotaContext === 'agricultural') {
        questions.push('How will this affect crop conditions?');
      }
    }

    // Alert-related follow-ups
    if (responseLower.includes('alert') || responseLower.includes('warning')) {
      questions.push('What safety precautions should I take?');
      questions.push('How long will these conditions last?');
    }

    // Planning-related follow-ups
    if (this.questionContext.timeFrame === 'weekend') {
      questions.push('What about the weather for next weekend?');
    }

    // South Dakota-specific follow-ups
    if (this.questionContext.southDakotaContext === 'agricultural') {
      questions.push('How does this weather pattern compare to typical conditions for this season?');
    }

    if (this.questionContext.southDakotaContext === 'recreational') {
      questions.push('Are there any weather-related restrictions for outdoor activities?');
    }

    return questions.slice(0, 3); // Limit to 3 follow-up questions
  }

  /**
   * Determines the type of response
   */
  private determineResponseType(response: string): ProcessedResponse['responseType'] {
    const responseLower = response.toLowerCase();

    if (responseLower.includes('alert') || responseLower.includes('warning') || responseLower.includes('severe')) {
      return 'alert';
    }

    if (responseLower.includes('tomorrow') || responseLower.includes('week') || responseLower.includes('forecast')) {
      return 'forecast';
    }

    if (responseLower.includes('plan') || responseLower.includes('schedule') || responseLower.includes('activity')) {
      return 'planning';
    }

    if (responseLower.includes('compare') || responseLower.includes('normal') || responseLower.includes('typical')) {
      return 'comparison';
    }

    return 'current';
  }

  /**
   * Enhances response format with structured information
   */
  private enhanceResponseFormat(response: string, recommendations: ActionableRecommendation[]): string {
    let enhanced = response;

    // Add safety recommendations at the beginning if high urgency
    const safetyRecommendations = recommendations.filter(rec => rec.urgency === 'high' && rec.category === 'safety');
    if (safetyRecommendations.length > 0) {
      enhanced = `⚠️ SAFETY ALERT: ${safetyRecommendations[0].action}. ${enhanced}`;
    }

    // Add planning recommendations at the end
    const planningRecommendations = recommendations.filter(rec => rec.category === 'planning');
    if (planningRecommendations.length > 0) {
      enhanced += `\n\n💡 Planning Tip: ${planningRecommendations[0].action}`;
    }

    return enhanced;
  }

  /**
   * Creates a fallback processed response when processing fails
   */
  private createFallbackProcessedResponse(originalResponse: string, error: any): ProcessedResponse {
    const fallbackValidation: ValidationResult = {
      isValid: false,
      sanitizedResponse: 'I apologize, but I encountered an error while processing the weather information. Please try again.',
      warnings: [`Processing error: ${error}`],
      confidence: 0,
    };

    return {
      originalResponse,
      processedResponse: fallbackValidation.sanitizedResponse,
      actionableRecommendations: [],
      weatherDataReferences: [],
      followUpQuestions: ['What is the current weather?', 'Are there any weather alerts?'],
      validationResult: fallbackValidation,
      confidence: 0,
      responseType: 'current',
    };
  }

  /**
   * Get processing statistics
   */
  getProcessingStats(): {
    weatherContextAvailable: boolean;
    questionContext: any;
    validationRules: any;
  } {
    return {
      weatherContextAvailable: !!this.weatherContext,
      questionContext: this.questionContext,
      validationRules: this.responseValidator.getValidationStats(),
    };
  }
} 