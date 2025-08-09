import { WeatherSummarizer, WeatherSummary } from './weather_summarizer';

// Prompt context interface
export interface PromptContext {
  question: string;
  location: string;
  timestamp: string;
  userId: string;
  weatherSummary?: WeatherSummary;
  conversationHistory?: string[];
  userPreferences?: {
    units: 'imperial' | 'metric';
    language: string;
  };
}

// Prompt template interface
export interface PromptTemplate {
  system: string;
  context: string;
  question: string;
  instructions: string;
}

export class PromptBuilder {
  private static readonly MAX_HISTORY_LENGTH = 5; // Keep last 5 exchanges for context
  private static readonly MAX_PROMPT_LENGTH = 4000; // Token limit for prompt

  /**
   * Builds a complete prompt for the AI service
   */
  static async buildPrompt(context: PromptContext): Promise<string> {
    try {
      console.log(`🔧 Building prompt for user ${context.userId} at ${context.location}`);

      // Get weather context if available
      let weatherContext = '';
      if (context.weatherSummary) {
        weatherContext = WeatherSummarizer.toPromptString(context.weatherSummary);
        console.log(`📊 Weather context length: ${weatherContext.length} characters`);
      }

      // Build conversation history
      const conversationHistory = this.buildConversationHistory(context.conversationHistory);
      
      // Create prompt template
      const template = this.createPromptTemplate(context, weatherContext, conversationHistory);
      
      // Assemble final prompt
      const finalPrompt = this.assemblePrompt(template);
      
      // Validate prompt length
      this.validatePromptLength(finalPrompt);
      
      // Log prompt statistics
      this.logPromptStats(finalPrompt, context);
      
      return finalPrompt;
    } catch (error) {
      console.error('Error building prompt:', error);
      throw new Error(`Failed to build prompt: ${error}`);
    }
  }

  /**
   * Creates the prompt template based on context
   */
  private static createPromptTemplate(
    context: PromptContext,
    weatherContext: string,
    conversationHistory: string
  ): PromptTemplate {
    const systemPrompt = this.getSystemPrompt(context.userPreferences);
    const contextSection = this.getContextSection(weatherContext, context.location);
    const questionSection = this.getQuestionSection(context.question);
    const instructions = this.getInstructions(context);

    return {
      system: systemPrompt,
      context: contextSection,
      question: questionSection,
      instructions: instructions,
    };
  }

  /**
   * Gets the enhanced system prompt based on user preferences
   */
  private static getSystemPrompt(preferences?: PromptContext['userPreferences']): string {
    const units = preferences?.units || 'imperial';
    const language = preferences?.language || 'English';
    const currentDate = new Date().toLocaleDateString('en-US', { 
      weekday: 'long', 
      year: 'numeric', 
      month: 'long', 
      day: 'numeric' 
    });
    
    // Calculate tomorrow's date for clarity
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const tomorrowDate = tomorrow.toLocaleDateString('en-US', { 
      weekday: 'long', 
      year: 'numeric', 
      month: 'long', 
      day: 'numeric' 
    });
    
    return `You are a specialized weather assistant for South Dakota, with deep knowledge of local weather patterns, geography, and seasonal conditions.

CURRENT DATE: ${currentDate}
TOMORROW: ${tomorrowDate}

IMPORTANT DATE CONTEXT:
- Today is ${currentDate}
- Tomorrow is ${tomorrowDate}
- When someone says "tomorrow", they mean ${tomorrowDate}
- When someone says "Friday", they mean ${tomorrowDate} (since today is Thursday)
- Always be precise about dates and avoid saying "tomorrow and Friday" when tomorrow IS Friday
- "One week from today" means exactly 7 days from today
- "Next [day name]" means the next occurrence of that day of the week

FORECAST DATA COVERAGE:
- You have access to 7+ days of forecast data (not just 3 days)
- The forecast includes current conditions plus multiple future days
- Always check the actual forecast data before saying information is unavailable
- If a date is mentioned in the forecast data, you have information for that date

SOUTH DAKOTA WEATHER EXPERTISE:
- Eastern SD: Humid continental climate with hot summers, cold winters, and frequent thunderstorms
- Western SD: Semi-arid climate with less precipitation, more wind, and temperature extremes
- Black Hills: Unique microclimate with higher precipitation and cooler temperatures
- Seasonal patterns: Spring tornadoes, summer thunderstorms, fall harvest weather, winter blizzards
- Agricultural considerations: Planting seasons, harvest timing, livestock weather stress

TEMPERATURE GUIDELINES:
- CURRENT TEMPERATURE: The temperature right now (from current conditions)
- HIGH TEMPERATURE: The maximum temperature expected for today (from forecast)
- LOW TEMPERATURE: The minimum temperature expected for today (from forecast)
- When asked about "high temperature today", refer to the forecast high, not current temperature
- When asked about "current temperature", refer to the current conditions
- Always specify whether you're talking about current, high, or low temperatures

RESPONSE GUIDELINES:
- Use ${units} units (${units === 'imperial' ? 'Fahrenheit, miles, inches' : 'Celsius, kilometers, millimeters'})
- Respond in ${language}
- Keep responses concise but informative (2-4 sentences)
- Base ALL information ONLY on the provided weather data
- Include specific, actionable recommendations
- Mention any weather alerts, warnings, or advisories
- Be conversational but professional and authoritative
- If weather data is insufficient, clearly state what information is missing
- Consider local South Dakota context and seasonal patterns
- Always clarify the date context (today, tomorrow, this weekend, etc.)
- Be precise about dates: if tomorrow is Friday, don't say "tomorrow and Friday"
- Check the forecast data carefully before saying information is unavailable

SAFETY PRIORITIES:
- Always prioritize safety information for severe weather
- Include specific actions for weather emergencies
- Consider vulnerable populations (elderly, children, outdoor workers)
- Mention travel impacts for significant weather events

Your role is to help South Dakotans make informed weather-related decisions for safety, planning, and daily activities.`;
  }

  /**
   * Gets the enhanced context section with weather data
   */
  private static getContextSection(weatherContext: string, location: string): string {
    if (!weatherContext) {
      return `Location: ${location}
Note: No current weather data available. Please provide general weather guidance based on typical South Dakota conditions for this area and time of year.`;
    }

    return `Location: ${location}

Current Weather Data:
${weatherContext}

South Dakota Context: Consider local geography, seasonal patterns, and typical weather behavior for this region.`;
  }

  /**
   * Gets the question section
   */
  private static getQuestionSection(question: string): string {
    return `User Question: ${question.trim()}`;
  }

  /**
   * Gets enhanced specific instructions based on question type and South Dakota context
   */
  private static getInstructions(context: PromptContext): string {
    const question = context.question.toLowerCase();
    const questionContext = this.extractQuestionContext(question);
    
    // Base instructions
    let instructions = 'Provide a helpful, actionable response based on the weather data provided. ';
    
    // Add South Dakota-specific context
    instructions += 'Consider local South Dakota weather patterns and seasonal conditions. ';
    
    // Temperature-specific instructions
    if (questionContext.weatherType === 'temperature') {
      instructions += 'Focus on temperature trends, current conditions, and temperature-related recommendations. ';
      if (question.includes('hot') || question.includes('heat')) {
        instructions += 'Consider heat stress for outdoor activities and vulnerable populations. ';
      }
      if (question.includes('cold') || question.includes('freeze')) {
        instructions += 'Consider frost protection, winter safety, and heating concerns. ';
      }
    }
    
    // Precipitation-specific instructions
    if (questionContext.weatherType === 'precipitation') {
      instructions += 'Focus on precipitation chances, amounts, and timing. ';
      if (question.includes('rain') || question.includes('storm')) {
        instructions += 'Include flood concerns, road conditions, and outdoor activity impacts. ';
      }
      if (question.includes('snow') || question.includes('blizzard')) {
        instructions += 'Include winter travel hazards, snow removal, and cold safety. ';
      }
    }
    
    // Wind-specific instructions
    if (questionContext.weatherType === 'wind') {
      instructions += 'Focus on wind speeds, directions, and any wind-related hazards. ';
      instructions += 'Consider impacts on outdoor activities, driving, and agricultural operations. ';
    }
    
    // Alert-specific instructions
    if (questionContext.weatherType === 'alerts') {
      instructions += 'Prioritize any active weather alerts or warnings. ';
      instructions += 'Provide specific safety recommendations and emergency actions if applicable. ';
    }
    
    // Planning-specific instructions
    if (questionContext.timeFrame === 'weekend' || question.includes('plan') || question.includes('outdoor')) {
      instructions += 'Provide planning-focused advice for outdoor activities, including best times and weather considerations. ';
      instructions += 'Consider South Dakota recreational activities and seasonal events. ';
    }
    
    // Agricultural considerations
    if (question.includes('farm') || question.includes('crop') || question.includes('agriculture') || 
        question.includes('plant') || question.includes('harvest')) {
      instructions += 'Include agricultural considerations for South Dakota farming and ranching operations. ';
    }
    
    // Travel considerations
    if (question.includes('travel') || question.includes('drive') || question.includes('road')) {
      instructions += 'Include travel safety considerations and road condition impacts. ';
    }
    
    return instructions;
  }

  /**
   * Builds conversation history for context
   */
  private static buildConversationHistory(history?: string[]): string {
    if (!history || history.length === 0) {
      return '';
    }

    // Take only the last few exchanges to stay within token limits
    const recentHistory = history.slice(-this.MAX_HISTORY_LENGTH);
    
    return `Recent Conversation Context:
${recentHistory.map((exchange, index) => `${index + 1}. ${exchange}`).join('\n')}

`;
  }

  /**
   * Assembles the final prompt from template
   */
  private static assemblePrompt(template: PromptTemplate): string {
    const sections = [
      template.system,
      '',
      template.context,
      '',
      template.question,
      '',
      template.instructions,
    ];

    return sections.join('\n');
  }

  /**
   * Validates prompt length to stay within token limits
   */
  private static validatePromptLength(prompt: string): void {
    const estimatedTokens = Math.ceil(prompt.length / 4); // Rough token estimation
    
    if (estimatedTokens > this.MAX_PROMPT_LENGTH) {
      console.warn(`⚠️ Prompt length warning: ${estimatedTokens} estimated tokens (limit: ${this.MAX_PROMPT_LENGTH})`);
      
      // Truncate if necessary (this should rarely happen with our summarization)
      if (estimatedTokens > this.MAX_PROMPT_LENGTH * 1.2) {
        throw new Error(`Prompt too long: ${estimatedTokens} tokens exceeds limit of ${this.MAX_PROMPT_LENGTH}`);
      }
    }
  }

  /**
   * Logs prompt statistics for monitoring
   */
  private static logPromptStats(prompt: string, context: PromptContext): void {
    const estimatedTokens = Math.ceil(prompt.length / 4);
    const hasWeatherData = context.weatherSummary !== undefined;
    
    console.log(`📝 Prompt: ${estimatedTokens} tokens, ${hasWeatherData ? 'with' : 'without'} weather data`);
  }

  /**
   * Creates an enhanced fallback prompt when weather data is unavailable
   */
  static createFallbackPrompt(context: PromptContext): string {
    const questionContext = this.extractQuestionContext(context.question);
    
    return `You are a specialized weather assistant for South Dakota.

Location: ${context.location}
Note: Current weather data is temporarily unavailable.

User Question: ${context.question}

Question Analysis:
- Type: ${questionContext.weatherType}
- Time Frame: ${questionContext.timeFrame}
- Urgency: ${questionContext.urgency}

Please provide general weather guidance for South Dakota, considering:
- Local seasonal patterns and typical conditions
- South Dakota geography and climate zones
- Safety considerations for the question type
- Recommendation to check local weather sources for current conditions

Mention that current conditions may vary and recommend users check local weather sources for the most up-to-date information.`;
  }

  /**
   * Enhanced question context extraction with South Dakota-specific analysis
   */
  static extractQuestionContext(question: string): {
    timeFrame: 'current' | 'today' | 'weekend' | 'week' | 'future';
    weatherType: 'general' | 'temperature' | 'precipitation' | 'wind' | 'alerts';
    urgency: 'low' | 'medium' | 'high';
    southDakotaContext: 'agricultural' | 'recreational' | 'travel' | 'general';
  } {
    const q = question.toLowerCase();
    
    // Determine time frame
    let timeFrame: 'current' | 'today' | 'weekend' | 'week' | 'future' = 'current';
    if (q.includes('today') || q.includes('tonight') || q.includes('tomorrow')) timeFrame = 'today';
    else if (q.includes('weekend')) timeFrame = 'weekend';
    else if (q.includes('week') || q.includes('7 day') || q.includes('a week from now') || q.includes('a week from today')) timeFrame = 'week';
    else if (q.includes('future') || q.includes('next week') || q.includes('upcoming')) timeFrame = 'future';
    // Handle specific day names - these should get extended forecast data
    else if (q.includes('sunday') || q.includes('monday') || q.includes('tuesday') || 
             q.includes('wednesday') || q.includes('thursday') || q.includes('friday') || 
             q.includes('saturday')) timeFrame = 'weekend';
    
    // Determine weather type
    let weatherType: 'general' | 'temperature' | 'precipitation' | 'wind' | 'alerts' = 'general';
    if (q.includes('temperature') || q.includes('hot') || q.includes('cold') || q.includes('freeze')) weatherType = 'temperature';
    else if (q.includes('rain') || q.includes('snow') || q.includes('precipitation') || q.includes('storm')) weatherType = 'precipitation';
    else if (q.includes('wind') || q.includes('breezy') || q.includes('gusty')) weatherType = 'wind';
    else if (q.includes('alert') || q.includes('warning') || q.includes('severe') || q.includes('emergency')) weatherType = 'alerts';
    
    // Determine urgency
    let urgency: 'low' | 'medium' | 'high' = 'low';
    if (q.includes('emergency') || q.includes('dangerous') || q.includes('severe') || q.includes('warning')) urgency = 'high';
    else if (q.includes('plan') || q.includes('important') || q.includes('travel')) urgency = 'medium';
    
    // Determine South Dakota context
    let southDakotaContext: 'agricultural' | 'recreational' | 'travel' | 'general' = 'general';
    if (q.includes('farm') || q.includes('crop') || q.includes('agriculture') || q.includes('plant') || q.includes('harvest')) southDakotaContext = 'agricultural';
    else if (q.includes('hunt') || q.includes('fish') || q.includes('camp') || q.includes('outdoor') || q.includes('recreation')) southDakotaContext = 'recreational';
    else if (q.includes('travel') || q.includes('drive') || q.includes('road') || q.includes('highway')) southDakotaContext = 'travel';
    
    return { timeFrame, weatherType, urgency, southDakotaContext };
  }
} 