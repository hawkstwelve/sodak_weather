import { WeatherSummary, DailyCondition } from './weather_summarizer';
import { PromptBuilder } from './prompt_builder';

// Context selection interface
export interface ContextSelection {
  currentConditions: boolean;
  shortTermForecast: boolean;
  extendedForecast: boolean;
  alerts: boolean;
  trends: boolean;
  historicalContext: boolean;
}

// Context manager interface
export interface ContextManager {
  selectContext(question: string, weatherSummary: WeatherSummary): WeatherSummary;
  getContextSelection(question: string): ContextSelection;
  enhanceContextWithHistorical(weatherSummary: WeatherSummary, location: string): Promise<WeatherSummary>;
}

export class SmartContextManager implements ContextManager {
  /**
   * Selects the most relevant weather context based on the question
   */
  selectContext(question: string, weatherSummary: WeatherSummary): WeatherSummary {
    const contextSelection = this.getContextSelection(question);
    

    
    // Create a filtered weather summary based on context selection
    const filteredSummary: WeatherSummary = {
      today: contextSelection.currentConditions ? weatherSummary.today : this.createEmptyDailyCondition(),
      next_3_days: [], // Will be populated based on context selection
      alerts: contextSelection.alerts ? weatherSummary.alerts : [],
      trends: contextSelection.trends ? weatherSummary.trends : '',
    };
    
    // Handle forecast data based on context selection
    if (contextSelection.shortTermForecast || contextSelection.extendedForecast) {
      // Include all available forecast data (up to 10 days) for both short-term and extended
      // The weather summarizer stores all 10 days in next_3_days field
      filteredSummary.next_3_days = weatherSummary.next_3_days;
    }
    
    return filteredSummary;
  }

  /**
   * Determines which context elements are relevant for a given question
   */
  getContextSelection(question: string): ContextSelection {
    const q = question.toLowerCase();
    const questionContext = PromptBuilder.extractQuestionContext(question);
    
    // Default context selection
    const selection: ContextSelection = {
      currentConditions: true, // Always include current conditions as baseline
      shortTermForecast: false,
      extendedForecast: false,
      alerts: false,
      trends: false,
      historicalContext: false,
    };
    
    // Time frame-based selection
    switch (questionContext.timeFrame) {
      case 'current':
        selection.currentConditions = true;
        selection.alerts = true; // Always include alerts for current conditions
        break;
        
      case 'today':
        selection.currentConditions = true;
        selection.shortTermForecast = true;
        selection.alerts = true;
        selection.trends = true;
        break;
        
      case 'weekend':
        selection.currentConditions = true;
        selection.shortTermForecast = true;
        selection.extendedForecast = true;
        selection.alerts = true;
        selection.trends = true;
        break;
        
      case 'week':
        selection.currentConditions = true;
        selection.shortTermForecast = true;
        selection.extendedForecast = true;
        selection.alerts = true;
        selection.trends = true;
        break;
        
      case 'future':
        selection.currentConditions = true;
        selection.extendedForecast = true;
        selection.trends = true;
        selection.historicalContext = true;
        break;
    }
    
    // Weather type-based selection
    switch (questionContext.weatherType) {
      case 'temperature':
        selection.currentConditions = true;
        selection.shortTermForecast = true;
        selection.trends = true;
        break;
        
      case 'precipitation':
        selection.currentConditions = true;
        selection.shortTermForecast = true;
        selection.alerts = true;
        selection.trends = true;
        break;
        
      case 'wind':
        selection.currentConditions = true;
        selection.shortTermForecast = true;
        selection.alerts = true;
        break;
        
      case 'alerts':
        selection.alerts = true;
        selection.currentConditions = true;
        break;
    }
    
    // South Dakota context-based selection
    switch (questionContext.southDakotaContext) {
      case 'agricultural':
        selection.currentConditions = true;
        selection.shortTermForecast = true;
        selection.extendedForecast = true;
        selection.trends = true;
        selection.historicalContext = true;
        break;
        
      case 'recreational':
        selection.currentConditions = true;
        selection.shortTermForecast = true;
        selection.alerts = true;
        selection.trends = true;
        break;
        
      case 'travel':
        selection.currentConditions = true;
        selection.shortTermForecast = true;
        selection.alerts = true;
        break;
    }
    
    // Urgency-based adjustments
    if (questionContext.urgency === 'high') {
      selection.alerts = true;
      selection.currentConditions = true;
    }
    
    // Keyword-based fine-tuning
    if (q.includes('right now') || q.includes('currently') || 
        (q.includes('now') && !q.includes('from now') && !q.includes('until now'))) {
      selection.currentConditions = true;
      selection.alerts = true;
      selection.shortTermForecast = false;
      selection.extendedForecast = false;
    }
    
    if (q.includes('plan') || q.includes('prepare') || q.includes('schedule')) {
      selection.extendedForecast = true;
      selection.trends = true;
    }
    
    if (q.includes('compare') || q.includes('difference') || q.includes('normal')) {
      selection.historicalContext = true;
      selection.trends = true;
    }
    
    return selection;
  }

  /**
   * Enhances weather context with historical data for comparison questions
   */
  async enhanceContextWithHistorical(weatherSummary: WeatherSummary, location: string): Promise<WeatherSummary> {
    try {
      // In a real implementation, this would fetch historical weather data
      // For now, we'll add placeholder historical context
      const enhancedSummary = { ...weatherSummary };
      
      // Add historical context for South Dakota
      const historicalContext = this.getSouthDakotaHistoricalContext(location, new Date());
      enhancedSummary.trends = `${enhancedSummary.trends} ${historicalContext}`;
      
      return enhancedSummary;
    } catch (error) {
      console.error('Error enhancing context with historical data:', error);
      return weatherSummary; // Return original if enhancement fails
    }
  }

  /**
   * Creates an empty daily condition for when context is not needed
   */
  private createEmptyDailyCondition(): DailyCondition {
    return {
      date: new Date().toISOString().split('T')[0],
      high_temp: 0,
      low_temp: 0,
      condition: 'Unknown',
      precipitation_chance: 0,
      wind_speed: '0 mph',
      humidity: 0,
    };
  }

  /**
   * Provides South Dakota-specific historical context
   */
  private getSouthDakotaHistoricalContext(location: string, date: Date): string {
    const month = date.getMonth() + 1; // 1-12
    const day = date.getDate();
    
    // South Dakota seasonal context
    const seasonalContext = this.getSeasonalContext(month, day);
    const regionalContext = this.getRegionalContext(location);
    
    return `Historical context: ${seasonalContext} ${regionalContext}`;
  }

  /**
   * Provides seasonal context for South Dakota
   */
  private getSeasonalContext(month: number, day: number): string {
    if (month === 3 || month === 4) {
      return 'Spring tornado season in South Dakota typically begins in March.';
    } else if (month === 5 || month === 6) {
      return 'Late spring brings frequent thunderstorms and severe weather to eastern South Dakota.';
    } else if (month === 7 || month === 8) {
      return 'Summer months feature hot temperatures and afternoon thunderstorms, especially in eastern SD.';
    } else if (month === 9 || month === 10) {
      return 'Fall harvest season with generally mild temperatures and decreasing precipitation.';
    } else if (month === 11 || month === 12) {
      return 'Early winter with increasing cold temperatures and potential for early snow.';
    } else if (month === 1 || month === 2) {
      return 'Deep winter with cold temperatures and frequent snow events, especially in eastern SD.';
    }
    
    return 'Typical seasonal weather patterns for South Dakota.';
  }

  /**
   * Provides regional context based on location
   */
  private getRegionalContext(location: string): string {
    const locationLower = location.toLowerCase();
    
    if (locationLower.includes('rapid city') || locationLower.includes('black hills')) {
      return 'Black Hills region experiences unique microclimate with higher precipitation and cooler temperatures.';
    } else if (locationLower.includes('sioux falls') || locationLower.includes('eastern')) {
      return 'Eastern South Dakota has humid continental climate with more precipitation and humidity.';
    } else if (locationLower.includes('rapid') || locationLower.includes('western')) {
      return 'Western South Dakota has semi-arid climate with less precipitation and more wind.';
    }
    
    return 'South Dakota experiences continental climate with four distinct seasons.';
  }

  /**
   * Optimizes context for token efficiency
   */
  optimizeContextForTokens(weatherSummary: WeatherSummary, maxTokens: number = 2000): WeatherSummary {
    const estimatedTokens = this.estimateTokens(weatherSummary);
    
    if (estimatedTokens <= maxTokens) {
      return weatherSummary;
    }
    
    console.log(`🔧 Optimizing context: ${estimatedTokens} tokens -> target ${maxTokens}`);
    
    // Start with most important elements
    const optimized: WeatherSummary = {
      today: weatherSummary.today,
      next_3_days: [],
      alerts: weatherSummary.alerts,
      trends: '',
    };
    
    // Add short-term forecast if space allows
    if (this.estimateTokens(optimized) + 500 < maxTokens) {
      optimized.next_3_days = weatherSummary.next_3_days.slice(0, 2); // Only first 2 days
    }
    
    // Add trends if space allows
    if (this.estimateTokens(optimized) + 200 < maxTokens) {
      optimized.trends = weatherSummary.trends;
    }
    
    console.log(`✅ Optimized context: ${this.estimateTokens(optimized)} tokens`);
    return optimized;
  }

  /**
   * Estimates token count for weather summary
   */
  private estimateTokens(weatherSummary: WeatherSummary): number {
    const summaryString = JSON.stringify(weatherSummary);
    return Math.ceil(summaryString.length / 4); // Rough estimation
  }
} 