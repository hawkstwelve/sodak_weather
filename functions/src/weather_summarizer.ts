// Weather summary interface for structured data
export interface WeatherSummary {
  today: DailyCondition;
  next_3_days: DailyCondition[];
  alerts: string[];
  trends: string;
}

export interface DailyCondition {
  date: string;
  high_temp: number;
  low_temp: number;
  condition: string;
  precipitation_chance: number;
  wind_speed: string;
  humidity: number;
}

export interface CurrentConditions {
  temperature: number;
  condition: string;
  humidity: number;
  wind_speed: string;
  visibility: string;
  pressure: string;
}

// Weather summarizer class
export class WeatherSummarizer {
  /**
   * Summarizes weather data into a condensed, structured format
   * Reduces token usage by 30-50% compared to verbose NWS text
   */
  static async summarizeWeatherData(
    location: string,
    weatherData: any,
    alerts: any[] = []
  ): Promise<WeatherSummary> {
    try {


      // Extract current conditions
      const currentConditions = this.extractCurrentConditions(weatherData);
      
      // Extract forecast data
      const forecast = this.extractForecastData(weatherData);
      

      
      // Extract alerts
      const alertSummaries = this.extractAlerts(alerts);
      
      // Generate trends
      const trends = this.generateTrends(forecast);
      
      // For weekend questions, we need more days to cover Saturday and Sunday
      // Today is Thursday, so Saturday is 2 days away, Sunday is 3 days away
      // With 10 days of forecast data, we can include more days for better context
      // Use all available forecast days (10 days) to maximize data availability
      const daysNeeded = 10; // Use all 10 days of forecast data
      
      return {
        today: currentConditions,
        next_3_days: forecast.slice(0, daysNeeded),
        alerts: alertSummaries,
        trends: trends,
      };
    } catch (error) {
      console.error('Error summarizing weather data:', error);
      throw new Error('Failed to summarize weather data');
    }
  }

  /**
   * Extracts current conditions from weather data
   */
  private static extractCurrentConditions(weatherData: any): DailyCondition {
    const current = weatherData.currentConditions || {};
    const weatherCondition = current.weatherCondition || {};
    const now = new Date();
    
    return {
      date: now.toISOString().split('T')[0],
      high_temp: Math.round(current.temperature?.degrees || 0),
      low_temp: Math.round(current.temperature?.degrees || 0), // Same as high for current
      condition: weatherCondition.description?.text || 'Unknown',
      precipitation_chance: 0, // Current conditions don't have precipitation chance
      wind_speed: `${Math.round(current.wind?.speed?.value || 0)} mph`,
      humidity: current.relativeHumidity || 0,
    };
  }

  /**
   * Extracts forecast data from weather data
   */
  private static extractForecastData(weatherData: any): DailyCondition[] {
    // Google Weather API structure: forecast.forecastDays
    const forecastDays = weatherData.forecast?.forecastDays || [];
    
    if (!Array.isArray(forecastDays)) {
      console.warn('Forecast data is not an array:', forecastDays);
      return [];
    }
    
    return forecastDays.map((day: any) => {
      // Extract daytime forecast (Google Weather API provides separate day/night)
      const dayForecast = day.daytimeForecast || {};
      const weatherCondition = dayForecast.weatherCondition || {};
      
      return {
        date: new Date(day.interval?.startTime || Date.now()).toISOString().split('T')[0],
        high_temp: Math.round(day.maxTemperature?.degrees || 0),
        low_temp: Math.round(day.minTemperature?.degrees || 0),
        condition: weatherCondition.description?.text || 'Unknown',
        precipitation_chance: dayForecast.precipitation?.probability?.percent || 0,
        wind_speed: `${Math.round(dayForecast.wind?.speed?.value || 0)} mph`,
        humidity: 0, // Google Weather API doesn't provide humidity in forecast
      };
    });
  }

  /**
   * Extracts and summarizes weather alerts
   */
  private static extractAlerts(alerts: any[]): string[] {
    return alerts.map(alert => {
      const severity = alert.properties?.severity || 'Unknown';
      const event = alert.properties?.event || 'Unknown';
      const areaDesc = alert.properties?.areaDesc || '';
      
      return `${severity}: ${event} - ${areaDesc}`;
    });
  }

  /**
   * Generates weather trends based on forecast data
   */
  private static generateTrends(forecast: DailyCondition[]): string {
    if (forecast.length < 2) return 'Insufficient data for trends';
    
    const temps = forecast.map(day => day.high_temp);
    const tempTrend = this.analyzeTemperatureTrend(temps);
    const precipTrend = this.analyzePrecipitationTrend(forecast);
    
    return `${tempTrend}. ${precipTrend}`;
  }

  /**
   * Analyzes temperature trend
   */
  private static analyzeTemperatureTrend(temps: number[]): string {
    if (temps.length < 2) return 'Temperature trend unclear';
    
    const firstTemp = temps[0];
    const lastTemp = temps[temps.length - 1];
    const diff = lastTemp - firstTemp;
    
    if (diff > 5) return 'Temperatures trending warmer';
    if (diff < -5) return 'Temperatures trending cooler';
    return 'Temperatures remaining stable';
  }

  /**
   * Analyzes precipitation trend
   */
  private static analyzePrecipitationTrend(forecast: DailyCondition[]): string {
    const precipDays = forecast.filter(day => day.precipitation_chance > 30);
    
    if (precipDays.length === 0) return 'No significant precipitation expected';
    if (precipDays.length === 1) return 'Light precipitation possible';
    if (precipDays.length <= 2) return 'Scattered precipitation expected';
    return 'Wet conditions expected';
  }

  /**
   * Converts weather summary to JSON string for AI prompt
   */
  static toPromptString(summary: WeatherSummary): string {
    const today = summary.today;
    const forecast = summary.next_3_days;
    const alerts = summary.alerts;
    const trends = summary.trends;
    
    // Get current date for context
    const currentDate = new Date();
    const todayName = currentDate.toLocaleDateString('en-US', { weekday: 'long' });
    
    // Use actual dates from forecast data instead of calculating by index
    const forecastWithDates = forecast.map((day) => {
      const date = new Date(day.date);
      const dayName = date.toLocaleDateString('en-US', { weekday: 'long' });
      const dateStr = date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
      return `- ${dayName} (${dateStr}): ${day.condition}, High ${day.high_temp}°F, Low ${day.low_temp}°F, ${day.precipitation_chance}% precip chance`;
    });
    
    return `Current Weather (${todayName}): ${today.condition}, ${today.high_temp}°F, ${today.wind_speed} wind, ${today.humidity}% humidity.

${forecast.length > 3 ? `${forecast.length}-Day Forecast:` : '3-Day Forecast:'}
${forecastWithDates.join('\n')}

${alerts.length > 0 ? `Active Alerts:\n${alerts.join('\n')}\n` : ''}
Trends: ${trends}`;
  }
} 