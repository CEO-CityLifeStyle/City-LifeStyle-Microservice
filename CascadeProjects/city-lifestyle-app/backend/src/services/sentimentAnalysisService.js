const natural = require('natural');
const Review = require('../models/review');
const Place = require('../models/place');

class SentimentAnalysisService {
  constructor() {
    this.tokenizer = new natural.WordTokenizer();
    this.analyzer = new natural.SentimentAnalyzer('English', natural.PorterStemmer, 'afinn');
    this.language = "EN"
    this.stemmer = natural.PorterStemmer;
    this.tfidf = new natural.TfIdf();
  }

  // Analyze sentiment of a single review
  async analyzeSentiment(text) {
    try {
      // Tokenize and stem the text
      const tokens = this.tokenizer.tokenize(text.toLowerCase());
      const stems = tokens.map(token => this.stemmer.stem(token));

      // Get sentiment score
      const score = this.analyzer.getSentiment(stems);

      // Classify sentiment
      const sentiment = this._classifySentiment(score);

      // Extract key phrases
      const keyPhrases = await this._extractKeyPhrases(text);

      return {
        score,
        sentiment,
        keyPhrases,
      };
    } catch (error) {
      throw new Error(`Failed to analyze sentiment: ${error.message}`);
    }
  }

  // Analyze sentiment of multiple reviews
  async analyzeBatchSentiment(reviewIds) {
    try {
      const reviews = await Review.find({ _id: { $in: reviewIds } });
      const results = [];

      for (const review of reviews) {
        const analysis = await this.analyzeSentiment(review.comment);
        results.push({
          reviewId: review._id,
          ...analysis,
        });
      }

      return results;
    } catch (error) {
      throw new Error(`Failed to analyze batch sentiment: ${error.message}`);
    }
  }

  // Get sentiment trends
  async getSentimentTrends(startDate, endDate) {
    try {
      const reviews = await Review.find({
        createdAt: { $gte: startDate, $lte: endDate },
      });

      const trends = {
        daily: {},
        overall: {
          positive: 0,
          neutral: 0,
          negative: 0,
          averageScore: 0,
        },
        keyPhrases: {},
      };

      for (const review of reviews) {
        const analysis = await this.analyzeSentiment(review.comment);
        const date = review.createdAt.toISOString().split('T')[0];

        // Update daily trends
        if (!trends.daily[date]) {
          trends.daily[date] = {
            positive: 0,
            neutral: 0,
            negative: 0,
            averageScore: 0,
            count: 0,
          };
        }

        trends.daily[date][analysis.sentiment]++;
        trends.daily[date].count++;
        trends.daily[date].averageScore = 
          (trends.daily[date].averageScore * (trends.daily[date].count - 1) + analysis.score) 
          / trends.daily[date].count;

        // Update overall trends
        trends.overall[analysis.sentiment]++;
        trends.overall.averageScore = 
          (trends.overall.averageScore * (reviews.indexOf(review)) + analysis.score) 
          / (reviews.indexOf(review) + 1);

        // Update key phrases
        analysis.keyPhrases.forEach(phrase => {
          trends.keyPhrases[phrase] = (trends.keyPhrases[phrase] || 0) + 1;
        });
      }

      return trends;
    } catch (error) {
      throw new Error(`Failed to get sentiment trends: ${error.message}`);
    }
  }

  // Get place sentiment analysis
  async getPlaceSentimentAnalysis(placeId) {
    try {
      const reviews = await Review.find({ place: placeId });
      const results = {
        overall: {
          positive: 0,
          neutral: 0,
          negative: 0,
          averageScore: 0,
        },
        keyPhrases: {},
        aspects: {},
      };

      for (const review of reviews) {
        const analysis = await this.analyzeSentiment(review.comment);
        
        // Update overall sentiment
        results.overall[analysis.sentiment]++;
        results.overall.averageScore = 
          (results.overall.averageScore * (reviews.indexOf(review)) + analysis.score) 
          / (reviews.indexOf(review) + 1);

        // Update key phrases
        analysis.keyPhrases.forEach(phrase => {
          results.keyPhrases[phrase] = (results.keyPhrases[phrase] || 0) + 1;
        });

        // Analyze aspects (e.g., service, food, ambiance)
        const aspectAnalysis = await this._analyzeAspects(review.comment);
        Object.keys(aspectAnalysis).forEach(aspect => {
          if (!results.aspects[aspect]) {
            results.aspects[aspect] = {
              positive: 0,
              neutral: 0,
              negative: 0,
              averageScore: 0,
              count: 0,
            };
          }

          results.aspects[aspect][aspectAnalysis[aspect].sentiment]++;
          results.aspects[aspect].count++;
          results.aspects[aspect].averageScore = 
            (results.aspects[aspect].averageScore * (results.aspects[aspect].count - 1) + aspectAnalysis[aspect].score) 
            / results.aspects[aspect].count;
        });
      }

      return results;
    } catch (error) {
      throw new Error(`Failed to get place sentiment analysis: ${error.message}`);
    }
  }

  // Helper methods
  _classifySentiment(score) {
    if (score > 0.2) return 'positive';
    if (score < -0.2) return 'negative';
    return 'neutral';
  }

  async _extractKeyPhrases(text) {
    try {
      // Add the document to TF-IDF
      this.tfidf.addDocument(text);

      // Get terms with their weights
      const terms = [];
      this.tfidf.listTerms(0).forEach(item => {
        if (item.tfidf > 0.5) { // Adjust threshold as needed
          terms.push(item.term);
        }
      });

      // Remove the document from TF-IDF
      this.tfidf.documents.pop();

      return terms;
    } catch (error) {
      return [];
    }
  }

  async _analyzeAspects(text) {
    const aspects = {
      service: {
        keywords: ['service', 'staff', 'waiter', 'waitress', 'employee'],
        score: 0,
        sentiment: 'neutral',
      },
      ambiance: {
        keywords: ['ambiance', 'atmosphere', 'decor', 'music', 'lighting'],
        score: 0,
        sentiment: 'neutral',
      },
      value: {
        keywords: ['price', 'value', 'worth', 'expensive', 'cheap'],
        score: 0,
        sentiment: 'neutral',
      },
      location: {
        keywords: ['location', 'parking', 'access', 'area', 'neighborhood'],
        score: 0,
        sentiment: 'neutral',
      },
    };

    const tokens = this.tokenizer.tokenize(text.toLowerCase());
    const stems = tokens.map(token => this.stemmer.stem(token));

    Object.keys(aspects).forEach(aspect => {
      const aspectTokens = [];
      let foundKeyword = false;

      tokens.forEach((token, index) => {
        if (aspects[aspect].keywords.includes(token)) {
          foundKeyword = true;
          // Get surrounding words for context
          const start = Math.max(0, index - 3);
          const end = Math.min(tokens.length, index + 4);
          aspectTokens.push(...stems.slice(start, end));
        }
      });

      if (foundKeyword) {
        aspects[aspect].score = this.analyzer.getSentiment(aspectTokens);
        aspects[aspect].sentiment = this._classifySentiment(aspects[aspect].score);
      }
    });

    return aspects;
  }
}

module.exports = new SentimentAnalysisService();
