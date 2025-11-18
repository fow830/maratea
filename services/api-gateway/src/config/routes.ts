export interface RouteConfig {
  path: string;
  target: string;
  methods?: string[];
  timeout?: number;
}

export const routes: RouteConfig[] = [
  {
    path: '/api/auth',
    target: process.env.AUTH_SERVICE_URL || 'http://auth-service:3001',
    timeout: 5000,
  },
  {
    path: '/api/organizations',
    target: process.env.ORGANIZATION_SERVICE_URL || 'http://organization-service:3002',
    timeout: 5000,
  },
  {
    path: '/api/users',
    target: process.env.USER_SERVICE_URL || 'http://user-service:3003',
    timeout: 5000,
  },
  {
    path: '/api/courses',
    target: process.env.CONTENT_SERVICE_URL || 'http://content-service:3004',
    timeout: 5000,
  },
  {
    path: '/api/streams',
    target: process.env.STREAM_SERVICE_URL || 'http://stream-service:3005',
    timeout: 5000,
  },
  {
    path: '/api/learning',
    target: process.env.LEARNING_SERVICE_URL || 'http://learning-service:3006',
    timeout: 5000,
  },
  // Дополнительные сервисы будут добавлены в следующих фазах
];
