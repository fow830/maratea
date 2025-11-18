import { z } from 'zod';

// Common validation schemas
export const emailSchema = z.string().email('Invalid email format');

export const passwordSchema = z
  .string()
  .min(8, 'Password must be at least 8 characters')
  .regex(/[A-Z]/, 'Password must contain at least one uppercase letter')
  .regex(/[a-z]/, 'Password must contain at least one lowercase letter')
  .regex(/[0-9]/, 'Password must contain at least one number');

export const paginationSchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(100).default(20),
});

// User validation schemas
export const createUserSchema = z.object({
  email: emailSchema,
  name: z.string().min(1, 'Name is required'),
  password: passwordSchema,
  role: z.enum(['admin', 'curator', 'student']),
  organizationId: z.string().uuid().optional(),
});

export const loginSchema = z.object({
  email: emailSchema,
  password: z.string().min(1, 'Password is required'),
});

// Organization validation schemas
export const createOrganizationSchema = z.object({
  name: z.string().min(1, 'Organization name is required'),
  domain: z.string().optional(),
  subscriptionPlan: z.enum(['basic', 'premium', 'enterprise']).default('basic'),
});

// Course validation schemas
export const createCourseSchema = z.object({
  title: z.string().min(1, 'Course title is required'),
  description: z.string().optional(),
  status: z.enum(['draft', 'published', 'archived']).default('draft'),
});

// Stream validation schemas
export const createStreamSchema = z.object({
  name: z.string().min(1, 'Stream name is required'),
  description: z.string().optional(),
  organizationId: z.string().uuid(),
  status: z.enum(['draft', 'active', 'completed', 'archived']).default('draft'),
});
