import * as crypto from 'crypto';
import * as admin from 'firebase-admin';
import { WeatherSummary } from './weather_summarizer';

// Cache entry interface
export interface CacheEntry {
  response: string;
  weatherContext: WeatherSummary;
  timestamp: number;
  questionHash: string;
  userId: string;
  location: string;
  question: string;
}

// Cache configuration
export interface CacheConfig {
  durationMs: number;
  maxEntries: number;
  collectionName: string;
}

export class CacheService {
  private static readonly DEFAULT_CONFIG: CacheConfig = {
    durationMs: 60 * 60 * 1000, // 1 hour
    maxEntries: 1000,
    collectionName: 'weather_chat_cache',
  };

  private db: admin.firestore.Firestore;
  private config: CacheConfig;

  constructor(config?: Partial<CacheConfig>) {
    this.db = admin.firestore();
    this.config = { ...CacheService.DEFAULT_CONFIG, ...config };
  }

  /**
   * Generate a hash-based cache key for a question
   */
  static generateCacheKey(question: string, location: string, date: string): string {
    const normalizedQuestion = question.toLowerCase().trim();
    const normalizedLocation = location.toLowerCase().trim();
    const input = `${normalizedLocation}_${date}_${normalizedQuestion}`;
    
    return crypto.createHash('sha256').update(input).digest('hex');
  }

  /**
   * Check if a cached response exists and is still valid
   */
  async getCachedResponse(
    question: string,
    location: string,
    userId: string
  ): Promise<CacheEntry | null> {
    try {
      const today = new Date().toISOString().split('T')[0];
      const cacheKey = CacheService.generateCacheKey(question, location, today);
      
  
      
      const docRef = this.db.collection(this.config.collectionName).doc(cacheKey);
      const doc = await docRef.get();
      
      if (!doc.exists) {
        console.log(`❌ Cache miss: No entry found for key ${cacheKey.substring(0, 8)}...`);
        return null;
      }
      
      const data = doc.data() as CacheEntry;
      const now = Date.now();
      
      // Check if cache entry is still valid
      if (now - data.timestamp > this.config.durationMs) {
        console.log(`⏰ Cache expired: Entry is ${Math.round((now - data.timestamp) / 1000 / 60)} minutes old`);
        
        // Delete expired entry
        await docRef.delete();
        return null;
      }
      
      console.log(`✅ Cache hit: Found valid entry for key ${cacheKey.substring(0, 8)}...`);
      return data;
      
    } catch (error) {
      console.error('Error retrieving cached response:', error);
      return null;
    }
  }

  /**
   * Store a response in the cache
   */
  async cacheResponse(
    question: string,
    location: string,
    response: string,
    weatherContext: WeatherSummary,
    userId: string
  ): Promise<void> {
    try {
      const today = new Date().toISOString().split('T')[0];
      const cacheKey = CacheService.generateCacheKey(question, location, today);
      const timestamp = Date.now();
      
      const cacheEntry: CacheEntry = {
        response,
        weatherContext,
        timestamp,
        questionHash: cacheKey,
        userId,
        location,
        question,
      };
      
      console.log(`💾 Caching response for key: ${cacheKey.substring(0, 8)}...`);
      
      // Store in Firestore
      await this.db.collection(this.config.collectionName).doc(cacheKey).set(cacheEntry);
      
      // Clean up old entries if we exceed max entries
      await this.cleanupOldEntries();
      
    } catch (error) {
      console.error('Error caching response:', error);
      // Don't throw error as caching is not critical
    }
  }

  /**
   * Clean up old cache entries to prevent database bloat
   */
  private async cleanupOldEntries(): Promise<void> {
    try {
      const cutoffTime = Date.now() - this.config.durationMs;
      
      // Get all cache entries older than the cutoff time
      const snapshot = await this.db
        .collection(this.config.collectionName)
        .where('timestamp', '<', cutoffTime)
        .limit(100) // Process in batches
        .get();
      
      if (snapshot.empty) {
        return;
      }
      
      console.log(`🧹 Cleaning up ${snapshot.docs.length} expired cache entries`);
      
      // Delete expired entries
      const batch = this.db.batch();
      snapshot.docs.forEach(doc => {
        batch.delete(doc.ref);
      });
      
      await batch.commit();
      
    } catch (error) {
      console.error('Error cleaning up old cache entries:', error);
    }
  }

  /**
   * Clear all cache entries for a specific user
   */
  async clearUserCache(userId: string): Promise<void> {
    try {
      console.log(`🗑️ Clearing cache for user: ${userId}`);
      
      const snapshot = await this.db
        .collection(this.config.collectionName)
        .where('userId', '==', userId)
        .get();
      
      if (snapshot.empty) {
        return;
      }
      
      const batch = this.db.batch();
      snapshot.docs.forEach(doc => {
        batch.delete(doc.ref);
      });
      
      await batch.commit();
      console.log(`✅ Cleared ${snapshot.docs.length} cache entries for user ${userId}`);
      
    } catch (error) {
      console.error('Error clearing user cache:', error);
    }
  }

  /**
   * Clear all cache entries
   */
  async clearAllCache(): Promise<void> {
    try {
      console.log('🗑️ Clearing all cache entries');
      
      const snapshot = await this.db
        .collection(this.config.collectionName)
        .limit(500) // Process in batches
        .get();
      
      if (snapshot.empty) {
        return;
      }
      
      const batch = this.db.batch();
      snapshot.docs.forEach(doc => {
        batch.delete(doc.ref);
      });
      
      await batch.commit();
      console.log(`✅ Cleared ${snapshot.docs.length} cache entries`);
      
    } catch (error) {
      console.error('Error clearing all cache:', error);
    }
  }

  /**
   * Get cache statistics
   */
  async getCacheStats(): Promise<{
    totalEntries: number;
    totalSize: number;
    oldestEntry: number;
    newestEntry: number;
    userCount: number;
  }> {
    try {
      const snapshot = await this.db
        .collection(this.config.collectionName)
        .get();
      
      if (snapshot.empty) {
        return {
          totalEntries: 0,
          totalSize: 0,
          oldestEntry: 0,
          newestEntry: 0,
          userCount: 0,
        };
      }
      
      const entries = snapshot.docs.map(doc => doc.data() as CacheEntry);
      const uniqueUsers = new Set(entries.map(entry => entry.userId));
      
      const timestamps = entries.map(entry => entry.timestamp);
      const totalSize = entries.reduce((sum, entry) => sum + entry.response.length, 0);
      
      return {
        totalEntries: entries.length,
        totalSize,
        oldestEntry: Math.min(...timestamps),
        newestEntry: Math.max(...timestamps),
        userCount: uniqueUsers.size,
      };
      
    } catch (error) {
      console.error('Error getting cache stats:', error);
      return {
        totalEntries: 0,
        totalSize: 0,
        oldestEntry: 0,
        newestEntry: 0,
        userCount: 0,
      };
    }
  }

  /**
   * Check if cache is working properly
   */
  async healthCheck(): Promise<{
    status: 'healthy' | 'unhealthy';
    message: string;
    details?: any;
  }> {
    try {
      // Try to write and read a test entry
      const testKey = 'health_check_test';
      const testEntry: CacheEntry = {
        response: 'test',
        weatherContext: {} as WeatherSummary,
        timestamp: Date.now(),
        questionHash: testKey,
        userId: 'health_check',
        location: 'test',
        question: 'test',
      };
      
      // Write test entry
      await this.db.collection(this.config.collectionName).doc(testKey).set(testEntry);
      
      // Read test entry
      const doc = await this.db.collection(this.config.collectionName).doc(testKey).get();
      
      if (!doc.exists) {
        return {
          status: 'unhealthy',
          message: 'Cache write/read test failed',
        };
      }
      
      // Clean up test entry
      await this.db.collection(this.config.collectionName).doc(testKey).delete();
      
      return {
        status: 'healthy',
        message: 'Cache service is working properly',
      };
      
    } catch (error) {
      return {
        status: 'unhealthy',
        message: `Cache health check failed: ${error}`,
        details: error,
      };
    }
  }

  /**
   * Get cache configuration
   */
  getConfig(): CacheConfig {
    return { ...this.config };
  }

  /**
   * Update cache configuration
   */
  updateConfig(newConfig: Partial<CacheConfig>): void {
    this.config = { ...this.config, ...newConfig };
    console.log('⚙️ Updated cache configuration:', this.config);
  }
} 