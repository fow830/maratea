// User types
export type UserRole = 'admin' | 'curator' | 'student';

export interface User {
  id: string;
  email: string;
  name: string;
  role: UserRole;
  organizationId?: string;
  createdAt: Date;
  updatedAt: Date;
}

// Organization types
export interface Organization {
  id: string;
  name: string;
  domain?: string;
  subscriptionPlan: 'basic' | 'premium' | 'enterprise';
  createdAt: Date;
  updatedAt: Date;
}

// Course types
export interface Course {
  id: string;
  title: string;
  description: string;
  status: 'draft' | 'published' | 'archived';
  createdAt: Date;
  updatedAt: Date;
}

// Stream types
export interface LearningStream {
  id: string;
  organizationId: string;
  name: string;
  description: string;
  status: 'draft' | 'active' | 'completed' | 'archived';
  createdAt: Date;
  updatedAt: Date;
}

// API Response types
export interface ApiResponse<T = unknown> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
    details?: unknown;
  };
  meta?: {
    requestId: string;
    timestamp: string;
  };
}

// Pagination types
export interface PaginationParams {
  page?: number;
  limit?: number;
}

export interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}
