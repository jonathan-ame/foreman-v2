export interface TavilySearchResult {
  title: string;
  url: string;
  content: string;
  score: number;
  rawContent?: string;
}

export interface TavilySearchResponse {
  query: string;
  results: TavilySearchResult[];
  responseTime: number;
}

export interface TavilyExtractResult {
  url: string;
  rawContent: string;
  text?: string;
}

export interface TavilyExtractResponse {
  results: TavilyExtractResult[];
  failedResults?: Array<{ url: string; error: string }>;
  responseTime: number;
}

export interface TavilyResearchResponse {
  query: string;
  answer: string;
  results: TavilySearchResult[];
  responseTime: number;
}

export interface TavilySearchOptions {
  query: string;
  maxResults?: number;
  searchDepth?: "basic" | "advanced";
  includeRawContent?: boolean;
  includeDomains?: string[];
  excludeDomains?: string[];
  topic?: "general" | "news";
  days?: number;
}

export interface TavilyExtractOptions {
  urls: string[];
  extractDepth?: "basic" | "advanced";
}

export interface TavilyResearchOptions {
  query: string;
  maxResults?: number;
  searchDepth?: "basic" | "advanced";
  includeDomains?: string[];
  excludeDomains?: string[];
}