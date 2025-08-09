import { GoogleGenerativeAI } from '@google/generative-ai';
import OpenAI from 'openai';
import * as functions from 'firebase-functions';

// Model information interface
export interface ModelInfo {
  name: string;
  provider: 'gemini' | 'openai';
  maxTokens: number;
  costPer1kTokens: number;
  capabilities: string[];
}

// AI service interface
export interface AIService {
  generateResponse(prompt: string): Promise<string>;
  getModelInfo(): ModelInfo;
  getEstimatedCost(tokens: number): number;
}

// Gemini AI Service implementation
export class GeminiService implements AIService {
  private genAI: GoogleGenerativeAI;
  private model: any;
  private modelInfo: ModelInfo;

  constructor(apiKey: string) {
    this.genAI = new GoogleGenerativeAI(apiKey);
    this.model = this.genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });
    
    this.modelInfo = {
      name: 'gemini-1.5-flash',
      provider: 'gemini',
      maxTokens: 8192,
      costPer1kTokens: 0.075, // $0.075 per 1M input tokens, $0.30 per 1M output tokens
      capabilities: ['text-generation', 'weather-analysis', 'context-aware'],
    };
  }

  async generateResponse(prompt: string): Promise<string> {
    try {
      const result = await this.model.generateContent(prompt);
      const response = await result.response;
      return response.text();
    } catch (error) {
      console.error('Gemini API error:', error);
      throw new Error(`Gemini API error: ${error}`);
    }
  }

  getModelInfo(): ModelInfo {
    return this.modelInfo;
  }

  getEstimatedCost(tokens: number): number {
    // Rough estimation - actual costs vary by input/output ratio
    return (tokens / 1000) * this.modelInfo.costPer1kTokens;
  }
}

// OpenAI Service implementation
export class OpenAIService implements AIService {
  private openai: OpenAI;
  private modelInfo: ModelInfo;

  constructor(apiKey: string) {
    this.openai = new OpenAI({ apiKey });
    
    this.modelInfo = {
      name: 'gpt-3.5-turbo',
      provider: 'openai',
      maxTokens: 4096,
      costPer1kTokens: 0.002, // $0.002 per 1K tokens
      capabilities: ['text-generation', 'weather-analysis', 'context-aware'],
    };
  }

  async generateResponse(prompt: string): Promise<string> {
    try {
      const completion = await this.openai.chat.completions.create({
        model: this.modelInfo.name,
        messages: [
          {
            role: 'system',
            content: 'You are a helpful weather assistant for South Dakota. Provide accurate, actionable weather information based on the data provided.',
          },
          {
            role: 'user',
            content: prompt,
          },
        ],
        max_tokens: 1000,
        temperature: 0.7,
      });

      return completion.choices[0]?.message?.content || 'No response generated';
    } catch (error) {
      console.error('OpenAI API error:', error);
      throw new Error(`OpenAI API error: ${error}`);
    }
  }

  getModelInfo(): ModelInfo {
    return this.modelInfo;
  }

  getEstimatedCost(tokens: number): number {
    return (tokens / 1000) * this.modelInfo.costPer1kTokens;
  }
}

// AI Service Factory
export class AIServiceFactory {
  private static instance: AIService | null = null;
  private static preferredProvider: 'gemini' | 'openai' = 'gemini';

  /**
   * Creates an AI service instance based on environment configuration
   */
  static createService(): AIService {
    if (this.instance) {
      return this.instance;
    }

    const geminiKey = functions.config().ai?.gemini_key;
    const openaiKey = functions.config().ai?.openai_key;

    // Try preferred provider first
    if (this.preferredProvider === 'gemini' && geminiKey) {
      this.instance = new GeminiService(geminiKey);
      console.log('Using Gemini AI service');
      return this.instance;
    }

    if (this.preferredProvider === 'openai' && openaiKey) {
      this.instance = new OpenAIService(openaiKey);
      console.log('Using OpenAI service');
      return this.instance;
    }

    // Fallback to available provider
    if (geminiKey) {
      this.instance = new GeminiService(geminiKey);
      console.log('Using Gemini AI service (fallback)');
      return this.instance;
    }

    if (openaiKey) {
      this.instance = new OpenAIService(openaiKey);
      console.log('Using OpenAI service (fallback)');
      return this.instance;
    }

    throw new Error('No AI service API keys configured');
  }

  /**
   * Sets the preferred AI provider
   */
  static setPreferredProvider(provider: 'gemini' | 'openai'): void {
    this.preferredProvider = provider;
    this.instance = null; // Reset instance to use new provider
  }

  /**
   * Gets the current AI service instance
   */
  static getService(): AIService {
    return this.createService();
  }

  /**
   * Resets the service instance (useful for testing or switching providers)
   */
  static reset(): void {
    this.instance = null;
  }
}

// Utility functions for cost tracking and monitoring
export class AIServiceUtils {
  /**
   * Estimates token count for a given text
   */
  static estimateTokenCount(text: string): number {
    // Rough estimation: 1 token ≈ 4 characters for English text
    return Math.ceil(text.length / 4);
  }

  /**
   * Logs AI service usage for monitoring
   */
  static logUsage(service: AIService, prompt: string, response: string): void {
    const promptTokens = this.estimateTokenCount(prompt);
    const responseTokens = this.estimateTokenCount(response);
    const totalTokens = promptTokens + responseTokens;
    const estimatedCost = service.getEstimatedCost(totalTokens);

    console.log(`AI Service Usage:
      Provider: ${service.getModelInfo().provider}
      Model: ${service.getModelInfo().name}
      Prompt tokens: ${promptTokens}
      Response tokens: ${responseTokens}
      Total tokens: ${totalTokens}
      Estimated cost: $${estimatedCost.toFixed(4)}`);
  }

  /**
   * Validates AI response quality
   */
  static validateResponse(response: string): boolean {
    if (!response || response.trim().length === 0) {
      return false;
    }

    // Check for common error patterns
    const errorPatterns = [
      /i'm sorry/i,
      /i cannot/i,
      /i don't have access/i,
      /i'm unable to/i,
    ];

    return !errorPatterns.some(pattern => pattern.test(response));
  }
} 